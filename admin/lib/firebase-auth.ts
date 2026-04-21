import type { AdminRole } from "@/lib/permissions";
import { getFirebaseAdminAuth } from "@/lib/firebase-admin";

type FirebaseLoginResult = {
  email: string;
  role: AdminRole;
} | null;
export type FirebaseLoginDetailedResult =
  | { ok: true; email: string; role: AdminRole }
  | {
      ok: false;
      reason:
        | "firebase_not_configured"
        | "missing_credentials"
        | "invalid_credentials"
        | "missing_id_token"
        | "firebase_admin_unavailable"
        | "token_verify_failed"
        | "missing_role_claim";
    };

const roleMap: Record<string, AdminRole> = {
  admin: "super_admin",
  super_admin: "super_admin",
  transport_admin: "transport_admin",
  viewer: "viewer",
};

function normalizeRole(input: unknown): AdminRole | null {
  if (!input) return null;
  const raw = String(input).trim().toLowerCase();
  return roleMap[raw] ?? null;
}

export function firebaseAuthEnabled() {
  return Boolean(
    process.env.FIREBASE_PROJECT_ID &&
      process.env.FIREBASE_WEB_API_KEY,
  );
}

export async function validateFirebaseAdminLogin(
  email: string,
  password: string,
): Promise<FirebaseLoginResult> {
  const result = await validateFirebaseAdminLoginDetailed(email, password);
  if (!result.ok) return null;
  return { email: result.email, role: result.role };
}

export async function validateFirebaseAdminLoginDetailed(
  email: string,
  password: string,
): Promise<FirebaseLoginDetailedResult> {
  if (!firebaseAuthEnabled()) return { ok: false, reason: "firebase_not_configured" };
  const apiKey = process.env.FIREBASE_WEB_API_KEY!;
  const normalized = email.trim().toLowerCase();
  if (!normalized || !password) return { ok: false, reason: "missing_credentials" };

  const resp = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        email: normalized,
        password,
        returnSecureToken: true,
      }),
      cache: "no-store",
    },
  );
  if (!resp.ok) return { ok: false, reason: "invalid_credentials" };
  const payload = (await resp.json()) as { idToken?: string; email?: string };
  if (!payload.idToken) return { ok: false, reason: "missing_id_token" };

  const auth = getFirebaseAdminAuth();
  if (!auth) return { ok: false, reason: "firebase_admin_unavailable" };

  let decoded;
  try {
    decoded = await auth.verifyIdToken(payload.idToken, true);
  } catch {
    return { ok: false, reason: "token_verify_failed" };
  }
  const role = normalizeRole(decoded.role);
  if (!role) return { ok: false, reason: "missing_role_claim" };

  return {
    ok: true,
    email: (payload.email ?? normalized).toLowerCase(),
    role: role,
  };
}
