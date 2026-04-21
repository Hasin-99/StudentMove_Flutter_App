import bcrypt from "bcryptjs";
import { Prisma } from "@prisma/client";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { getFirebaseAdminAuth, getFirebaseAdminFirestore } from "@/lib/firebase-admin";
import type { AdminRole } from "@/lib/permissions";
import { prisma } from "@/lib/prisma";
import { logHybridPath } from "@/lib/runtime-diagnostics";

type PrismaRole = "SUPER_ADMIN" | "TRANSPORT_ADMIN" | "VIEWER";

export type AppUserRecord = {
  id: string;
  fullName: string;
  email: string;
  phone: string | null;
  studentId: string | null;
  department: string | null;
  role: PrismaRole;
  isActive: boolean;
  preferredRoutes: string[];
  createdAt: Date;
  updatedAt: Date;
};

type ListUsersInput = {
  q: string;
  status: "all" | "active" | "inactive";
  department: string;
  page: number;
  perPage: number;
};

const roleToClaim: Record<PrismaRole, AdminRole> = {
  SUPER_ADMIN: "super_admin",
  TRANSPORT_ADMIN: "transport_admin",
  VIEWER: "viewer",
};

function roleFromClaim(input: unknown): PrismaRole {
  const raw = String(input ?? "").trim().toLowerCase();
  if (raw === "super_admin" || raw === "admin") return "SUPER_ADMIN";
  if (raw === "transport_admin") return "TRANSPORT_ADMIN";
  return "VIEWER";
}

function mapUserWriteError(error: unknown): "duplicate_email" | "duplicate_student_id" | null {
  const message = String((error as { message?: string })?.message ?? "").toLowerCase();
  if (message === "duplicate_email") return "duplicate_email";
  if (message === "duplicate_student_id") return "duplicate_student_id";
  if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2002") {
    const target = String((error.meta as { target?: unknown } | undefined)?.target ?? "").toLowerCase();
    if (target.includes("student")) return "duplicate_student_id";
    return "duplicate_email";
  }
  const code = String((error as { code?: string })?.code ?? "").toLowerCase();
  if (code.includes("auth/email-already-exists") || message.includes("email-already-exists")) {
    return "duplicate_email";
  }
  if (message.includes("student") && message.includes("exists")) {
    return "duplicate_student_id";
  }
  return null;
}

function dataProvider() {
  return (process.env.ADMIN_DATA_PROVIDER ?? "hybrid").toLowerCase();
}

function firestoreEnabled() {
  return Boolean(process.env.FIREBASE_PROJECT_ID);
}

function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.map((v) => String(v).trim()).filter(Boolean);
}

function asDate(value: unknown, fallback = new Date()) {
  if (value instanceof Date) return value;
  if (value instanceof Timestamp) return value.toDate();
  if (typeof value === "string" || typeof value === "number") {
    const d = new Date(value);
    if (!Number.isNaN(d.getTime())) return d;
  }
  return fallback;
}

function filterAndPaginate(
  users: AppUserRecord[],
  input: ListUsersInput,
): { items: AppUserRecord[]; totalUsers: number; totalPages: number; currentPage: number } {
  const q = input.q.trim().toLowerCase();
  const department = input.department.trim().toLowerCase();
  const filtered = users.filter((u) => {
    if (input.status === "active" && !u.isActive) return false;
    if (input.status === "inactive" && u.isActive) return false;
    if (department && (u.department ?? "").trim().toLowerCase() !== department) return false;
    if (!q) return true;
    return [u.fullName, u.email, u.phone ?? "", u.studentId ?? ""]
      .join(" ")
      .toLowerCase()
      .includes(q);
  });
  const totalUsers = filtered.length;
  const totalPages = Math.max(Math.ceil(totalUsers / input.perPage), 1);
  const currentPage = Math.min(Math.max(input.page, 1), totalPages);
  const start = (currentPage - 1) * input.perPage;
  return {
    items: filtered.slice(start, start + input.perPage),
    totalUsers,
    totalPages,
    currentPage,
  };
}

async function fsListAllUsers(): Promise<AppUserRecord[]> {
  const db = getFirebaseAdminFirestore();
  const auth = getFirebaseAdminAuth();
  if (!db) throw new Error("firebase_unavailable");

  const [usersSnap, prefsSnap] = await Promise.all([
    db.collection("users").get(),
    db.collection("userPreferences").get(),
  ]);
  const authRoleByUid = new Map<string, PrismaRole>();
  if (auth) {
    try {
      const authPage = await auth.listUsers(1000);
      for (const u of authPage.users) {
        authRoleByUid.set(u.uid, roleFromClaim(u.customClaims?.role));
      }
    } catch (error) {
      logHybridPath({
        store: "users",
        operation: "fsListAllUsers.roles",
        path: "firebase",
        reason: error instanceof Error ? error.message : "firebase_auth_unavailable",
      });
    }
  }
  const routesByUid = new Map<string, string[]>();
  for (const p of prefsSnap.docs) {
    routesByUid.set(p.id, asStringArray(p.data().savedRoutes));
  }
  return usersSnap.docs.map((doc) => {
    const d = doc.data();
    const claimRole = authRoleByUid.get(doc.id);
    const fsRole = String((d as { role?: unknown }).role ?? "").toLowerCase();
    const derivedRole: PrismaRole =
      claimRole && claimRole !== "VIEWER"
        ? claimRole
        : fsRole === "staff"
          ? "TRANSPORT_ADMIN"
          : "VIEWER";
    return {
      id: doc.id,
      fullName: String(d.fullName ?? ""),
      email: String(d.email ?? ""),
      phone: d.phone == null ? null : String(d.phone),
      studentId: d.studentId == null ? null : String(d.studentId),
      department: d.department == null ? null : String(d.department),
      role: derivedRole,
      isActive: d.isActive == null ? true : Boolean(d.isActive),
      preferredRoutes: routesByUid.get(doc.id) ?? [],
      createdAt: asDate(d.createdAt),
      updatedAt: asDate(d.updatedAt),
    };
  });
}

async function fsGetById(id: string): Promise<AppUserRecord | null> {
  const db = getFirebaseAdminFirestore();
  const auth = getFirebaseAdminAuth();
  if (!db || !auth) throw new Error("firebase_unavailable");
  const [userDoc, authUser] = await Promise.all([
    db.collection("users").doc(id).get(),
    auth.getUser(id).catch(() => null),
  ]);
  if (!userDoc.exists) return null;
  const d = userDoc.data() as Record<string, unknown>;
  const prefDoc = await db.collection("userPreferences").doc(id).get();
  return {
    id,
    fullName: String(d.fullName ?? ""),
    email: String(d.email ?? ""),
    phone: d.phone == null ? null : String(d.phone),
    studentId: d.studentId == null ? null : String(d.studentId),
    department: d.department == null ? null : String(d.department),
    role: roleFromClaim(authUser?.customClaims?.role),
    isActive: d.isActive == null ? true : Boolean(d.isActive),
    preferredRoutes: prefDoc.exists
      ? asStringArray((prefDoc.data() as Record<string, unknown>).savedRoutes)
      : [],
    createdAt: asDate(d.createdAt),
    updatedAt: asDate(d.updatedAt),
  };
}

async function fsCreateUser(input: {
  fullName: string;
  email: string;
  phone: string | null;
  studentId: string | null;
  department: string | null;
  role: PrismaRole;
  password?: string;
}): Promise<AppUserRecord> {
  const db = getFirebaseAdminFirestore();
  const auth = getFirebaseAdminAuth();
  if (!db || !auth) throw new Error("firebase_unavailable");
  if (input.studentId) {
    const studentExists = await db
      .collection("users")
      .where("studentId", "==", input.studentId)
      .limit(1)
      .get();
    if (!studentExists.empty) {
      throw new Error("duplicate_student_id");
    }
  }

  const firebaseUser = await auth.createUser({
    email: input.email,
    password:
      input.password && input.password.length >= 8
        ? input.password
        : `Temp${Math.random().toString(36).slice(2)}A!9`,
    displayName: input.fullName,
    disabled: false,
  });
  await auth.setCustomUserClaims(firebaseUser.uid, { role: roleToClaim[input.role] });
  const firestoreRole =
    input.role === "SUPER_ADMIN" || input.role === "TRANSPORT_ADMIN" ? "staff" : "student";
  await db.collection("users").doc(firebaseUser.uid).set({
    uid: firebaseUser.uid,
    fullName: input.fullName,
    email: input.email,
    phone: input.phone,
    studentId: input.studentId,
    department: input.department,
    role: firestoreRole,
    isActive: true,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return {
    id: firebaseUser.uid,
    fullName: input.fullName,
    email: input.email,
    phone: input.phone,
    studentId: input.studentId,
    department: input.department,
    role: input.role,
    isActive: true,
    preferredRoutes: [],
    createdAt: new Date(),
    updatedAt: new Date(),
  };
}

async function fsUpdateUser(
  id: string,
  input: {
    fullName: string;
    email: string;
    phone: string | null;
    studentId: string | null;
    department: string | null;
    role: PrismaRole;
  },
) {
  const db = getFirebaseAdminFirestore();
  const auth = getFirebaseAdminAuth();
  if (!db || !auth) throw new Error("firebase_unavailable");
  const existingDoc = await db.collection("users").doc(id).get();
  const existing = existingDoc.data() as Record<string, unknown> | undefined;
  const existingEmail = String(existing?.email ?? "").trim().toLowerCase();
  const existingStudentId =
    existing?.studentId == null ? null : String(existing.studentId).trim();
  if (input.email !== existingEmail) {
    const emailExists = await db.collection("users").where("email", "==", input.email).limit(1).get();
    if (!emailExists.empty && emailExists.docs[0].id !== id) {
      throw new Error("duplicate_email");
    }
  }
  if (input.studentId && input.studentId !== existingStudentId) {
    const studentExists = await db
      .collection("users")
      .where("studentId", "==", input.studentId)
      .limit(1)
      .get();
    if (!studentExists.empty && studentExists.docs[0].id !== id) {
      throw new Error("duplicate_student_id");
    }
  }
  const firestoreRole =
    input.role === "SUPER_ADMIN" || input.role === "TRANSPORT_ADMIN" ? "staff" : "student";
  await Promise.all([
    auth.updateUser(id, { email: input.email, displayName: input.fullName }),
    auth.setCustomUserClaims(id, { role: roleToClaim[input.role] }),
    db.collection("users").doc(id).set(
      {
        fullName: input.fullName,
        email: input.email,
        phone: input.phone,
        studentId: input.studentId,
        department: input.department,
        role: firestoreRole,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    ),
  ]);
}

async function fsToggleUserActive(id: string): Promise<{ from: boolean; to: boolean; email: string }> {
  const db = getFirebaseAdminFirestore();
  const auth = getFirebaseAdminAuth();
  if (!db || !auth) throw new Error("firebase_unavailable");
  const existing = await fsGetById(id);
  if (!existing) throw new Error("user_not_found");
  const to = !existing.isActive;
  await Promise.all([
    auth.updateUser(id, { disabled: !to }),
    db.collection("users").doc(id).set({ isActive: to, updatedAt: FieldValue.serverTimestamp() }, { merge: true }),
  ]);
  return { from: existing.isActive, to, email: existing.email };
}

async function fsDeleteUser(id: string): Promise<AppUserRecord | null> {
  const db = getFirebaseAdminFirestore();
  const auth = getFirebaseAdminAuth();
  if (!db || !auth) throw new Error("firebase_unavailable");
  const existing = await fsGetById(id);
  await Promise.all([
    auth.deleteUser(id).catch(() => undefined),
    db.collection("users").doc(id).delete().catch(() => undefined),
    db.collection("userPreferences").doc(id).delete().catch(() => undefined),
  ]);
  return existing;
}

async function fsResetPassword(id: string, newPassword: string) {
  const auth = getFirebaseAdminAuth();
  if (!auth) throw new Error("firebase_unavailable");
  await auth.updateUser(id, { password: newPassword });
}

async function fsSetResetToken(id: string, resetToken: string, validMinutes: number) {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const ttl = Math.min(Math.max(validMinutes, 5), 1440);
  const resetTokenHash = await bcrypt.hash(resetToken, 12);
  const resetTokenExpiresAt = new Date(Date.now() + ttl * 60 * 1000);
  await db.collection("users").doc(id).set(
    { resetTokenHash, resetTokenExpiresAt, updatedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
  return ttl;
}

export async function listUsersForAdmin(input: ListUsersInput) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      const users = await fsListAllUsers();
      const departments = [...new Set(users.map((u) => (u.department ?? "").trim()).filter(Boolean))].sort();
      const pageData = filterAndPaginate(
        users.sort((a, b) => {
          if (a.isActive !== b.isActive) return a.isActive ? -1 : 1;
          return b.createdAt.getTime() - a.createdAt.getTime();
        }),
        input,
      );
      logHybridPath({ store: "users", operation: "listUsersForAdmin", path: "firebase" });
      return { ...pageData, departments };
    } catch (error) {
      logHybridPath({
        store: "users",
        operation: "listUsersForAdmin",
        path: "prisma_fallback",
        reason: error instanceof Error ? error.message : "firebase_error",
      });
      if (provider === "firebase") {
        // Keep users page renderable when Firebase is temporarily unavailable.
        return {
          items: [],
          totalUsers: 0,
          totalPages: 1,
          currentPage: Math.max(input.page, 1),
          departments: [],
        };
      }
    }
  }

  const where = {
    ...(input.status === "active"
      ? { isActive: true }
      : input.status === "inactive"
        ? { isActive: false }
        : {}),
    ...(input.department ? { department: input.department } : {}),
    ...(input.q
      ? {
          OR: [
            { fullName: { contains: input.q, mode: "insensitive" as const } },
            { email: { contains: input.q, mode: "insensitive" as const } },
            { phone: { contains: input.q, mode: "insensitive" as const } },
            { studentId: { contains: input.q, mode: "insensitive" as const } },
          ],
        }
      : {}),
  };
  const totalUsers = await prisma.appUser.count({ where });
  const totalPages = Math.max(Math.ceil(totalUsers / input.perPage), 1);
  const currentPage = Math.min(input.page, totalPages);
  const users = await prisma.appUser.findMany({
    where,
    skip: (currentPage - 1) * input.perPage,
    take: input.perPage,
    orderBy: [{ isActive: "desc" }, { createdAt: "desc" }],
  });
  const departments = await prisma.appUser.findMany({
    select: { department: true },
    distinct: ["department"],
    where: { department: { not: null } },
    orderBy: { department: "asc" },
  });
  logHybridPath({
    store: "users",
    operation: "listUsersForAdmin",
    path: provider === "prisma" ? "prisma" : "prisma_fallback",
  });
  return {
    items: users.map((u) => ({
      id: u.id,
      fullName: u.fullName,
      email: u.email,
      phone: u.phone,
      studentId: u.studentId,
      department: u.department,
      role: u.role,
      isActive: u.isActive,
      preferredRoutes: asStringArray(u.preferredRoutes),
      createdAt: u.createdAt,
      updatedAt: u.updatedAt,
    })),
    totalUsers,
    totalPages,
    currentPage,
    departments: departments.map((d) => d.department).filter((d): d is string => Boolean(d)),
  };
}

export async function getUserCounts() {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      const db = getFirebaseAdminFirestore();
      if (!db) throw new Error("firebase_unavailable");
      const users = await db.collection("users").get();
      logHybridPath({ store: "users", operation: "getUserCounts", path: "firebase" });
      return {
        totalUsers: users.size,
        activeUsers: users.docs.filter((doc) => {
          const data = doc.data() as { isActive?: unknown };
          return data.isActive == null ? true : Boolean(data.isActive);
        }).length,
      };
    } catch (error) {
      logHybridPath({
        store: "users",
        operation: "getUserCounts",
        path: "prisma_fallback",
        reason: error instanceof Error ? error.message : "firebase_error",
      });
      if (provider === "firebase") {
        // Keep dashboard usable during temporary Firebase outages.
        return { totalUsers: 0, activeUsers: 0 };
      }
    }
  }
  const [totalUsers, activeUsers] = await Promise.all([
    prisma.appUser.count(),
    prisma.appUser.count({ where: { isActive: true } }),
  ]);
  logHybridPath({
    store: "users",
    operation: "getUserCounts",
    path: provider === "prisma" ? "prisma" : "prisma_fallback",
  });
  return { totalUsers, activeUsers };
}

export async function createUserRecord(input: {
  fullName: string;
  email: string;
  phone: string | null;
  studentId: string | null;
  department: string | null;
  role: PrismaRole;
  password?: string;
}) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      return await fsCreateUser(input);
    } catch (error) {
      const mapped = mapUserWriteError(error);
      if (mapped) throw new Error(mapped);
      if (provider === "firebase") throw error;
    }
  }
  const { password, ...rest } = input;
  const passwordHash = password && password.length >= 8 ? await bcrypt.hash(password, 12) : null;
  let row;
  try {
    row = await prisma.appUser.create({
      data: { ...rest, passwordHash },
    });
  } catch (error) {
    const mapped = mapUserWriteError(error);
    if (mapped) throw new Error(mapped);
    throw error;
  }
  return {
    id: row.id,
    fullName: row.fullName,
    email: row.email,
    phone: row.phone,
    studentId: row.studentId,
    department: row.department,
    role: row.role,
    isActive: row.isActive,
    preferredRoutes: asStringArray(row.preferredRoutes),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

export async function getUserById(id: string): Promise<AppUserRecord | null> {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      return await fsGetById(id);
    } catch {
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const row = await prisma.appUser.findUnique({ where: { id } });
  if (!row) return null;
  return {
    id: row.id,
    fullName: row.fullName,
    email: row.email,
    phone: row.phone,
    studentId: row.studentId,
    department: row.department,
    role: row.role,
    isActive: row.isActive,
    preferredRoutes: asStringArray(row.preferredRoutes),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

export async function updateUserById(
  id: string,
  input: {
    fullName: string;
    email: string;
    phone: string | null;
    studentId: string | null;
    department: string | null;
    role: PrismaRole;
  },
) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      await fsUpdateUser(id, input);
      return;
    } catch (error) {
      const mapped = mapUserWriteError(error);
      if (mapped) throw new Error(mapped);
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  try {
    await prisma.appUser.update({ where: { id }, data: input });
  } catch (error) {
    const mapped = mapUserWriteError(error);
    if (mapped) throw new Error(mapped);
    throw error;
  }
}

export async function toggleUserActiveById(id: string): Promise<{ from: boolean; to: boolean; email: string }> {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      return await fsToggleUserActive(id);
    } catch {
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const user = await prisma.appUser.findUnique({ where: { id } });
  if (!user) throw new Error("user_not_found");
  await prisma.appUser.update({ where: { id }, data: { isActive: !user.isActive } });
  return { from: user.isActive, to: !user.isActive, email: user.email };
}

export async function deleteUserById(id: string): Promise<AppUserRecord | null> {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      return await fsDeleteUser(id);
    } catch {
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const existing = await prisma.appUser.findUnique({ where: { id } });
  await prisma.appUser.delete({ where: { id } });
  return existing
    ? {
        id: existing.id,
        fullName: existing.fullName,
        email: existing.email,
        phone: existing.phone,
        studentId: existing.studentId,
        department: existing.department,
        role: existing.role,
        isActive: existing.isActive,
        preferredRoutes: asStringArray(existing.preferredRoutes),
        createdAt: existing.createdAt,
        updatedAt: existing.updatedAt,
      }
    : null;
}

export async function resetUserPasswordById(id: string, newPassword: string) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      await fsResetPassword(id, newPassword);
      return;
    } catch {
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const passwordHash = await bcrypt.hash(newPassword, 12);
  await prisma.appUser.update({
    where: { id },
    data: { passwordHash, resetTokenHash: null, resetTokenExpiresAt: null },
  });
}

export async function setUserResetTokenById(id: string, resetToken: string, validMinutes: number) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      return await fsSetResetToken(id, resetToken, validMinutes);
    } catch {
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const ttl = Number.isFinite(validMinutes) ? Math.min(Math.max(validMinutes, 5), 1440) : 30;
  const resetTokenHash = await bcrypt.hash(resetToken, 12);
  const resetTokenExpiresAt = new Date(Date.now() + ttl * 60 * 1000);
  await prisma.appUser.update({ where: { id }, data: { resetTokenHash, resetTokenExpiresAt } });
  return ttl;
}

export async function createPublicUser(input: {
  fullName: string;
  email: string;
  phone: string | null;
  studentId: string | null;
  department: string | null;
  password: string;
}) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      const created = await fsCreateUser({ ...input, role: "VIEWER", password: input.password });
      logHybridPath({ store: "users", operation: "createPublicUser", path: "firebase" });
      return {
        id: created.id,
        fullName: created.fullName,
        email: created.email,
        isActive: created.isActive,
      };
    } catch (error) {
      logHybridPath({
        store: "users",
        operation: "createPublicUser",
        path: "prisma_fallback",
        reason: error instanceof Error ? error.message : "firebase_error",
      });
      if (provider === "firebase") throw error;
    }
  }
  const passwordHash = await bcrypt.hash(input.password, 12);
  const user = await prisma.appUser.create({
    data: {
      fullName: input.fullName,
      email: input.email,
      passwordHash,
      phone: input.phone,
      studentId: input.studentId,
      department: input.department,
      role: "VIEWER",
    },
    select: { id: true, fullName: true, email: true, isActive: true },
  });
  logHybridPath({
    store: "users",
    operation: "createPublicUser",
    path: provider === "prisma" ? "prisma" : "prisma_fallback",
  });
  return user;
}

export async function getPreferredRoutesByEmail(email: string): Promise<string[] | null> {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      const db = getFirebaseAdminFirestore();
      if (!db) throw new Error("firebase_unavailable");
      const userQuery = await db.collection("users").where("email", "==", email).limit(1).get();
      if (userQuery.empty) return null;
      const uid = userQuery.docs[0].id;
      const prefDoc = await db.collection("userPreferences").doc(uid).get();
      if (!prefDoc.exists) return [];
      const raw = prefDoc.data() as Record<string, unknown>;
      const routes = asStringArray(raw.savedRoutes);
      logHybridPath({ store: "users", operation: "getPreferredRoutesByEmail", path: "firebase" });
      return routes;
    } catch (error) {
      logHybridPath({
        store: "users",
        operation: "getPreferredRoutesByEmail",
        path: "prisma_fallback",
        reason: error instanceof Error ? error.message : "firebase_error",
      });
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const user = await prisma.appUser.findUnique({ where: { email }, select: { preferredRoutes: true } });
  if (!user) return null;
  logHybridPath({
    store: "users",
    operation: "getPreferredRoutesByEmail",
    path: provider === "prisma" ? "prisma" : "prisma_fallback",
  });
  return asStringArray(user.preferredRoutes);
}

export async function setPreferredRoutesByEmail(email: string, routes: string[]): Promise<boolean> {
  const cleaned = routes.map((r) => r.trim()).filter((r) => r.length > 0).slice(0, 100);
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      const db = getFirebaseAdminFirestore();
      if (!db) throw new Error("firebase_unavailable");
      const userQuery = await db.collection("users").where("email", "==", email).limit(1).get();
      if (userQuery.empty) return false;
      const uid = userQuery.docs[0].id;
      await db
        .collection("userPreferences")
        .doc(uid)
        .set({ savedRoutes: cleaned, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
      return true;
    } catch {
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const user = await prisma.appUser.findUnique({ where: { email } });
  if (!user) return false;
  await prisma.appUser.update({ where: { email }, data: { preferredRoutes: cleaned } });
  return true;
}

export function mapKnownCreateError(error: unknown): "user_already_exists" | "database_unavailable" {
  if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2002") {
    return "user_already_exists";
  }
  const maybe = String((error as { code?: string; message?: string })?.code ?? "");
  const msg = String((error as { message?: string })?.message ?? "");
  if (maybe.includes("auth/email-already-exists") || msg.includes("email-already-exists")) {
    return "user_already_exists";
  }
  return "database_unavailable";
}
