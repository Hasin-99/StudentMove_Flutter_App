import { getApps, initializeApp, cert, App, type ServiceAccount } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

function normalizeServiceAccountJson(raw: string): string {
  let value = raw.trim();
  if (
    (value.startsWith('"') && value.endsWith('"')) ||
    (value.startsWith("'") && value.endsWith("'"))
  ) {
    value = value.slice(1, -1);
  }
  return value;
}

function escapeLiteralPrivateKeyNewlines(rawJson: string): string {
  return rawJson.replace(
    /"private_key"\s*:\s*"([\s\S]*?)"\s*,\s*"client_email"/,
    (_m, keyBody: string) =>
      `"private_key":"${keyBody.replace(/\r?\n/g, "\\n")}","client_email"`,
  );
}

function parseServiceAccount(): ServiceAccount | null {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) return null;
  const normalized = normalizeServiceAccountJson(raw);
  const attempts: string[] = [
    normalized,
    normalized.replace(/\\"/g, '"'),
    escapeLiteralPrivateKeyNewlines(normalized),
    escapeLiteralPrivateKeyNewlines(normalized.replace(/\\"/g, '"')),
  ];
  for (const candidate of attempts) {
    try {
      const parsed = JSON.parse(candidate) as ServiceAccount & { private_key?: string };
      if (typeof parsed.private_key === "string") {
        parsed.private_key = parsed.private_key.replace(/\\n/g, "\n");
      }
      return parsed;
    } catch {
      // try next parse strategy
    }
  }
  return null;
}

let app: App | null = null;

export function getFirebaseAdminApp(): App | null {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  if (!projectId) return null;

  if (getApps().length > 0) {
    return getApps()[0]!;
  }

  if (app) return app;

  const serviceAccount = parseServiceAccount();
  if (!serviceAccount) {
    // In hybrid mode, prefer a clean fallback to Prisma instead of
    // triggering ADC/metadata lookups that emit runtime warnings.
    console.warn("[firebase-admin] service account parse failed");
    return null;
  }
  try {
    app = initializeApp({
      credential: cert(serviceAccount),
      projectId,
    });
    return app;
  } catch (error) {
    console.error("[firebase-admin] initializeApp failed", error);
    return null;
  }
}

export function getFirebaseAdminAuth() {
  const firebaseApp = getFirebaseAdminApp();
  if (!firebaseApp) return null;
  return getAuth(firebaseApp);
}

export function getFirebaseAdminFirestore() {
  const firebaseApp = getFirebaseAdminApp();
  if (!firebaseApp) return null;
  return getFirestore(firebaseApp);
}
