import { compare, hash } from "bcryptjs";
import { getFirebaseAdminAuth } from "@/lib/firebase-admin";
import { prisma } from "@/lib/prisma";
import { logHybridPath } from "@/lib/runtime-diagnostics";
import type { AdminRole } from "@/lib/permissions";

function authProvider() {
  return (process.env.ADMIN_AUTH_PROVIDER ?? "hybrid").toLowerCase();
}

function firebaseAuthEnabled() {
  return Boolean(process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_WEB_API_KEY);
}

async function verifyPasswordWithFirebase(email: string, password: string): Promise<boolean> {
  const apiKey = process.env.FIREBASE_WEB_API_KEY;
  if (!apiKey) return false;
  const resp = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
      cache: "no-store",
    },
  );
  return resp.ok;
}

async function changePasswordFirebase(email: string, currentPassword: string, newPassword: string) {
  const auth = getFirebaseAdminAuth();
  if (!auth) return { ok: false as const, reason: "firebase_unavailable" as const };
  const verified = await verifyPasswordWithFirebase(email, currentPassword);
  if (!verified) return { ok: false as const, reason: "invalid_current" as const };
  const user = await auth.getUserByEmail(email).catch(() => null);
  if (!user || user.disabled) return { ok: false as const, reason: "not_found" as const };
  await auth.updateUser(user.uid, { password: newPassword });
  return { ok: true as const, id: user.uid, email: user.email ?? email };
}

async function changePasswordPrisma(email: string, currentPassword: string, newPassword: string) {
  const admin = await prisma.adminAccount.findUnique({
    where: { email },
  });
  if (!admin || !admin.isActive) return { ok: false as const, reason: "not_found" as const };
  const ok = await compare(currentPassword, admin.passwordHash);
  if (!ok) return { ok: false as const, reason: "invalid_current" as const };
  const passwordHash = await hash(newPassword, 12);
  await prisma.adminAccount.update({
    where: { id: admin.id },
    data: { passwordHash },
  });
  return { ok: true as const, id: admin.id, email: admin.email };
}

export async function changeAdminPassword(
  emailRaw: string,
  currentPassword: string,
  newPassword: string,
) {
  const email = emailRaw.trim().toLowerCase();
  const provider = authProvider();

  if (provider !== "prisma" && firebaseAuthEnabled()) {
    const firebaseResult = await changePasswordFirebase(email, currentPassword, newPassword);
    if (firebaseResult.ok) {
      logHybridPath({ store: "security", operation: "changeAdminPassword", path: "firebase" });
      return firebaseResult;
    }
    if (provider === "firebase") return firebaseResult;
    logHybridPath({
      store: "security",
      operation: "changeAdminPassword",
      path: "prisma_fallback",
      reason: firebaseResult.reason,
    });
  }

  const result = await changePasswordPrisma(email, currentPassword, newPassword);
  logHybridPath({
    store: "security",
    operation: "changeAdminPassword",
    path: provider === "prisma" ? "prisma" : "prisma_fallback",
  });
  return result;
}

function roleFromFirebaseClaim(input: unknown): AdminRole {
  const raw = String(input ?? "").trim().toLowerCase();
  if (raw === "super_admin" || raw === "admin") return "super_admin";
  if (raw === "transport_admin") return "transport_admin";
  return "viewer";
}

async function resetAdminPasswordFirebase(email: string, newPassword: string) {
  const auth = getFirebaseAdminAuth();
  if (!auth) return { ok: false as const, reason: "firebase_unavailable" as const };
  const user = await auth.getUserByEmail(email).catch(() => null);
  if (!user || user.disabled) return { ok: false as const, reason: "not_found" as const };
  const role = roleFromFirebaseClaim(user.customClaims?.role);
  if (role === "viewer") return { ok: false as const, reason: "not_admin" as const };
  await auth.updateUser(user.uid, { password: newPassword });
  return { ok: true as const, id: user.uid, email: user.email ?? email };
}

async function resetAdminPasswordPrisma(email: string, newPassword: string) {
  const admin = await prisma.adminAccount.findUnique({
    where: { email },
  });
  if (!admin || !admin.isActive) return { ok: false as const, reason: "not_found" as const };
  const passwordHash = await hash(newPassword, 12);
  await prisma.adminAccount.update({
    where: { id: admin.id },
    data: { passwordHash },
  });
  return { ok: true as const, id: admin.id, email: admin.email };
}

export async function resetAdminPasswordBySuperAdmin(emailRaw: string, newPassword: string) {
  const email = emailRaw.trim().toLowerCase();
  const provider = authProvider();

  if (provider !== "prisma" && firebaseAuthEnabled()) {
    const firebaseResult = await resetAdminPasswordFirebase(email, newPassword);
    if (firebaseResult.ok) {
      logHybridPath({ store: "security", operation: "resetAdminPasswordBySuperAdmin", path: "firebase" });
      return firebaseResult;
    }
    if (provider === "firebase") return firebaseResult;
    logHybridPath({
      store: "security",
      operation: "resetAdminPasswordBySuperAdmin",
      path: "prisma_fallback",
      reason: firebaseResult.reason,
    });
  }

  const result = await resetAdminPasswordPrisma(email, newPassword);
  logHybridPath({
    store: "security",
    operation: "resetAdminPasswordBySuperAdmin",
    path: provider === "prisma" ? "prisma" : "prisma_fallback",
  });
  return result;
}
