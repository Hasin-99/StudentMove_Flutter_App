import { compare } from "bcryptjs";
import {
  validateFirebaseAdminLoginDetailed,
  firebaseAuthEnabled,
} from "@/lib/firebase-auth";
import { prisma } from "@/lib/prisma";
import type { AdminRole } from "@/lib/permissions";

const roleMap = {
  SUPER_ADMIN: "super_admin",
  TRANSPORT_ADMIN: "transport_admin",
  VIEWER: "viewer",
} as const;

export async function validateAdminLogin(email: string, password: string): Promise<{
  email: string;
  role: AdminRole;
} | null> {
  const authProvider = (process.env.ADMIN_AUTH_PROVIDER ?? "hybrid").toLowerCase();
  if (authProvider !== "prisma") {
    try {
      const detailed = await validateFirebaseAdminLoginDetailed(email, password);
      if (detailed.ok) {
        return { email: detailed.email, role: detailed.role };
      }
      if (!detailed.ok) {
        console.warn("[admin-login] firebase login denied", {
          email: email.trim().toLowerCase(),
          reason: detailed.reason,
        });
      }
      if (authProvider === "firebase") return null;
    } catch {
      if (authProvider === "firebase") return null;
    }
  }

  // If Firebase is configured but no matching admin role claim exists,
  // fallback works only in hybrid mode.
  if (authProvider === "firebase" && firebaseAuthEnabled()) {
    return null;
  }

  const normalized = email.trim().toLowerCase();
  if (!normalized || !password) return null;

  let admin:
    | {
        id: string;
        email: string;
        role: keyof typeof roleMap;
        isActive: boolean;
        passwordHash: string;
      }
    | null = null;
  try {
    admin = await prisma.adminAccount.findUnique({
      where: { email: normalized },
    });
  } catch {
    // Avoid hard-crashing login page on transient DB pool issues.
    return null;
  }
  if (!admin || !admin.isActive) return null;

  const ok = await compare(password, admin.passwordHash);
  if (!ok) return null;

  try {
    await prisma.adminAccount.update({
      where: { id: admin.id },
      data: { lastLoginAt: new Date() },
    });
  } catch {
    // Non-critical bookkeeping; keep successful login flow.
  }

  return {
    email: admin.email,
    role: roleMap[admin.role],
  };
}
