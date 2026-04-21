import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { Prisma } from "@prisma/client";
import { prisma } from "@/lib/prisma";
import { getFirebaseAdminFirestore } from "@/lib/firebase-admin";
import { logHybridPath } from "@/lib/runtime-diagnostics";

type AnnouncementRecord = {
  id: string;
  announcementKey?: string | null;
  title: string;
  body: string;
  targetDepartments: string[];
  targetRoutes: string[];
  isPinned: boolean;
  isActive: boolean;
  publishAt: Date;
  expiresAt: Date | null;
};

type AnnouncementCreateInput = Omit<AnnouncementRecord, "id" | "announcementKey">;
type AnnouncementUpdateInput = AnnouncementCreateInput;

type ActiveUserProfile = {
  department: string;
  preferredRoutes: string[];
};

function dataProvider() {
  return (process.env.ADMIN_DATA_PROVIDER ?? "hybrid").toLowerCase();
}

function firestoreEnabled() {
  return Boolean(process.env.FIREBASE_PROJECT_ID);
}

function toStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.map((v) => String(v).trim()).filter(Boolean);
}

function toDate(value: unknown, fallback: Date): Date {
  if (!value) return fallback;
  if (value instanceof Date) return value;
  if (value instanceof Timestamp) return value.toDate();
  if (typeof value === "string" || typeof value === "number") {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) return parsed;
  }
  return fallback;
}

function normalizeText(value: string) {
  return value
    .trim()
    .toLowerCase()
    .replace(/\s+/g, " ")
    .replace(/[^a-z0-9 ]+/g, "")
    .trim();
}

function normalizeTargets(values: string[]) {
  return values
    .map((v) => normalizeText(v))
    .filter(Boolean)
    .sort()
    .join("|");
}

function toMinute(value: Date) {
  const d = new Date(value);
  d.setSeconds(0, 0);
  return d;
}

function nextMinute(value: Date) {
  return new Date(value.getTime() + 60_000);
}

function buildAnnouncementKey(input: AnnouncementCreateInput) {
  return [
    normalizeText(input.title),
    normalizeText(input.body),
    normalizeTargets(input.targetDepartments),
    normalizeTargets(input.targetRoutes),
    toMinute(input.publishAt).toISOString(),
  ].join("::");
}

function normalizeAnnouncementInput(input: AnnouncementCreateInput): AnnouncementCreateInput {
  return {
    ...input,
    publishAt: toMinute(input.publishAt),
  };
}

function isDuplicateAnnouncementContent(
  left: Pick<AnnouncementCreateInput, "title" | "body" | "targetDepartments" | "targetRoutes" | "publishAt">,
  right: Pick<AnnouncementCreateInput, "title" | "body" | "targetDepartments" | "targetRoutes" | "publishAt">,
) {
  return (
    normalizeText(left.title) === normalizeText(right.title) &&
    normalizeText(left.body) === normalizeText(right.body) &&
    normalizeTargets(left.targetDepartments) === normalizeTargets(right.targetDepartments) &&
    normalizeTargets(left.targetRoutes) === normalizeTargets(right.targetRoutes) &&
    toMinute(left.publishAt).getTime() === toMinute(right.publishAt).getTime()
  );
}

function fromFirestoreDoc(
  id: string,
  raw: Record<string, unknown>,
): AnnouncementRecord {
  const publishAt = toDate(raw.publishAt, new Date());
  const expiresAtRaw = raw.expiresAt;
  const expiresAt =
    expiresAtRaw == null ? null : toDate(expiresAtRaw, publishAt);
  return {
    id,
    announcementKey: raw.announcementKey == null ? null : String(raw.announcementKey),
    title: String(raw.title ?? ""),
    body: String(raw.body ?? ""),
    targetDepartments: toStringArray(raw.targetDepartments),
    targetRoutes: toStringArray(raw.targetRoutes),
    isPinned: Boolean(raw.isPinned),
    isActive: raw.isActive == null ? true : Boolean(raw.isActive),
    publishAt,
    expiresAt,
  };
}

function fromPrismaRow(row: {
  id: string;
  announcementKey: string | null;
  title: string;
  body: string;
  targetDepartments: unknown;
  targetRoutes: unknown;
  isPinned: boolean;
  isActive: boolean;
  publishAt: Date;
  expiresAt: Date | null;
}): AnnouncementRecord {
  return {
    id: row.id,
    announcementKey: row.announcementKey ?? null,
    title: row.title,
    body: row.body,
    targetDepartments: toStringArray(row.targetDepartments),
    targetRoutes: toStringArray(row.targetRoutes),
    isPinned: row.isPinned,
    isActive: row.isActive,
    publishAt: row.publishAt,
    expiresAt: row.expiresAt,
  };
}

async function fsListAdminAnnouncements(): Promise<AnnouncementRecord[]> {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const snap = await db
    .collection("announcements")
    .orderBy("publishAt", "desc")
    .get();
  const rows = snap.docs.map((doc) =>
    fromFirestoreDoc(doc.id, doc.data() as Record<string, unknown>),
  );
  rows.sort((a, b) => {
    if (a.isPinned === b.isPinned) return b.publishAt.getTime() - a.publishAt.getTime();
    return a.isPinned ? -1 : 1;
  });
  return rows;
}

async function fsCreateAnnouncement(input: AnnouncementCreateInput): Promise<string> {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const normalizedInput = normalizeAnnouncementInput(input);
  const announcementKey = buildAnnouncementKey(normalizedInput);
  const minuteStart = toMinute(normalizedInput.publishAt);
  const minuteEnd = nextMinute(minuteStart);
  const sameMinuteSnap = await db
    .collection("announcements")
    .where("publishAt", ">=", minuteStart)
    .where("publishAt", "<", minuteEnd)
    .get();
  for (const doc of sameMinuteSnap.docs) {
    const existing = fromFirestoreDoc(doc.id, doc.data() as Record<string, unknown>);
    if (
      isDuplicateAnnouncementContent(existing, normalizedInput)
    ) {
      throw new Error("duplicate_announcement");
    }
  }
  const existingLegacy = await db
    .collection("announcements")
    .where("announcementKey", "==", announcementKey)
    .limit(1)
    .get();
  if (!existingLegacy.empty) {
    throw new Error("duplicate_announcement");
  }
  const lockRef = db.collection("announcementUniqueLocks").doc(announcementKey);
  const ref = db.collection("announcements").doc();
  await db.runTransaction(async (tx) => {
    const lockDoc = await tx.get(lockRef);
    if (lockDoc.exists) throw new Error("duplicate_announcement");
    tx.set(ref, {
      announcementKey,
      title: normalizedInput.title,
      body: normalizedInput.body,
      targetDepartments: normalizedInput.targetDepartments,
      targetRoutes: normalizedInput.targetRoutes,
      isPinned: normalizedInput.isPinned,
      isActive: normalizedInput.isActive,
      publishAt: normalizedInput.publishAt,
      expiresAt: normalizedInput.expiresAt,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(lockRef, {
      announcementId: ref.id,
      announcementKey,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  return ref.id;
}

async function fsUpdateAnnouncement(id: string, input: Partial<AnnouncementUpdateInput>) {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const ref = db.collection("announcements").doc(id);
  await db.runTransaction(async (tx) => {
    const existingDoc = await tx.get(ref);
    if (!existingDoc.exists) return;
    const raw = existingDoc.data() as Record<string, unknown>;
    const merged: AnnouncementCreateInput = normalizeAnnouncementInput({
      title: input.title ?? String(raw.title ?? ""),
      body: input.body ?? String(raw.body ?? ""),
      targetDepartments: input.targetDepartments ?? toStringArray(raw.targetDepartments),
      targetRoutes: input.targetRoutes ?? toStringArray(raw.targetRoutes),
      isPinned: input.isPinned ?? Boolean(raw.isPinned),
      isActive: input.isActive ?? Boolean(raw.isActive),
      publishAt: input.publishAt ?? toDate(raw.publishAt, new Date()),
      expiresAt:
        input.expiresAt === undefined
          ? raw.expiresAt == null
            ? null
            : toDate(raw.expiresAt, new Date())
          : input.expiresAt,
    });
    const nextKey = buildAnnouncementKey(merged);
    const prevKey = String(raw.announcementKey ?? "");
    const minuteStart = toMinute(merged.publishAt);
    const minuteEnd = nextMinute(minuteStart);
    const sameMinuteSnap = await db
      .collection("announcements")
      .where("publishAt", ">=", minuteStart)
      .where("publishAt", "<", minuteEnd)
      .get();
    for (const doc of sameMinuteSnap.docs) {
      if (doc.id === id) continue;
      const existing = fromFirestoreDoc(doc.id, doc.data() as Record<string, unknown>);
      if (isDuplicateAnnouncementContent(existing, merged)) {
        throw new Error("duplicate_announcement");
      }
    }
    if (nextKey !== prevKey) {
      const nextLockRef = db.collection("announcementUniqueLocks").doc(nextKey);
      const nextLockDoc = await tx.get(nextLockRef);
      if (nextLockDoc.exists) {
        const lockOwner = String(nextLockDoc.data()?.announcementId ?? "");
        if (lockOwner && lockOwner !== id) throw new Error("duplicate_announcement");
      }
      tx.set(nextLockRef, {
        announcementId: id,
        announcementKey: nextKey,
        updatedAt: FieldValue.serverTimestamp(),
      });
      if (prevKey) {
        tx.delete(db.collection("announcementUniqueLocks").doc(prevKey));
      }
    }
    tx.set(
      ref,
      {
        ...input,
        publishAt: input.publishAt ? toMinute(input.publishAt) : undefined,
        announcementKey: nextKey,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}

async function fsDeleteAnnouncement(id: string) {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const ref = db.collection("announcements").doc(id);
  const doc = await ref.get();
  const key = String(doc.data()?.announcementKey ?? "");
  const batch = db.batch();
  batch.delete(ref);
  if (key) {
    batch.delete(db.collection("announcementUniqueLocks").doc(key));
  }
  await batch.commit();
}

async function fsGetAnnouncement(id: string): Promise<AnnouncementRecord | null> {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const doc = await db.collection("announcements").doc(id).get();
  if (!doc.exists) return null;
  return fromFirestoreDoc(id, doc.data() as Record<string, unknown>);
}

async function fsListActiveUserProfiles(): Promise<ActiveUserProfile[]> {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const usersSnap = await db.collection("users").get();
  const prefsSnap = await db.collection("userPreferences").get();
  const routesByUid = new Map<string, string[]>();
  for (const doc of prefsSnap.docs) {
    const raw = doc.data();
    routesByUid.set(doc.id, toStringArray(raw.savedRoutes));
  }
  return usersSnap.docs
    .map((doc) => {
      const raw = doc.data();
      const isActive = raw.isActive == null ? true : Boolean(raw.isActive);
      if (!isActive) return null;
      return {
        department: String(raw.department ?? "").trim().toLowerCase(),
        preferredRoutes: (routesByUid.get(doc.id) ?? [])
          .map((v) => v.trim().toLowerCase())
          .filter(Boolean),
      } satisfies ActiveUserProfile;
    })
    .filter((v): v is ActiveUserProfile => Boolean(v));
}

async function prismaListAdminAnnouncements(): Promise<AnnouncementRecord[]> {
  const rows = await prisma.announcement.findMany({
    orderBy: [{ isPinned: "desc" }, { publishAt: "desc" }],
  });
  return rows.map(fromPrismaRow);
}

export async function listAdminAnnouncements(): Promise<AnnouncementRecord[]> {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      const rows = await fsListAdminAnnouncements();
      logHybridPath({ store: "announcements", operation: "listAdminAnnouncements", path: "firebase" });
      return rows;
    } catch (error) {
      logHybridPath({
        store: "announcements",
        operation: "listAdminAnnouncements",
        path: "prisma_fallback",
        reason: error instanceof Error ? error.message : "firebase_error",
      });
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  logHybridPath({
    store: "announcements",
    operation: "listAdminAnnouncements",
    path: provider === "prisma" ? "prisma" : "prisma_fallback",
  });
  return prismaListAdminAnnouncements();
}

export async function createAnnouncementRecord(input: AnnouncementCreateInput): Promise<string> {
  const normalizedInput = normalizeAnnouncementInput(input);
  const announcementKey = buildAnnouncementKey(normalizedInput);
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      return await fsCreateAnnouncement(normalizedInput);
    } catch (error) {
      if (error instanceof Error && error.message === "duplicate_announcement") {
        throw error;
      }
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const prismaSameMinute = await prisma.announcement.findMany({
    where: {
      publishAt: {
        gte: toMinute(normalizedInput.publishAt),
        lt: nextMinute(toMinute(normalizedInput.publishAt)),
      },
    },
    select: {
      title: true,
      body: true,
      targetDepartments: true,
      targetRoutes: true,
      publishAt: true,
    },
  });
  const hasRuntimeDuplicate = prismaSameMinute.some((row) =>
    isDuplicateAnnouncementContent(
      {
        title: row.title,
        body: row.body,
        targetDepartments: toStringArray(row.targetDepartments),
        targetRoutes: toStringArray(row.targetRoutes),
        publishAt: row.publishAt,
      },
      normalizedInput,
    ),
  );
  if (hasRuntimeDuplicate) {
    throw new Error("duplicate_announcement");
  }
  const existing = await prisma.announcement.findFirst({
    where: {
      announcementKey,
      NOT: { announcementKey: null },
    },
    select: { id: true },
  });
  if (existing) {
    throw new Error("duplicate_announcement");
  }
  try {
    const row = await prisma.announcement.create({
      data: { ...normalizedInput, announcementKey },
    });
    return row.id;
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2002") {
      throw new Error("duplicate_announcement");
    }
    throw error;
  }
}

export async function getAnnouncementById(id: string): Promise<AnnouncementRecord | null> {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      return await fsGetAnnouncement(id);
    } catch {
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const row = await prisma.announcement.findUnique({ where: { id } });
  return row ? fromPrismaRow(row) : null;
}

export async function updateAnnouncementById(
  id: string,
  input: Partial<AnnouncementUpdateInput>,
) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      await fsUpdateAnnouncement(id, {
        ...input,
        publishAt: input.publishAt ? toMinute(input.publishAt) : undefined,
      });
      return;
    } catch (error) {
      if (error instanceof Error && error.message === "duplicate_announcement") {
        throw error;
      }
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const existing = await prisma.announcement.findUnique({ where: { id } });
  if (!existing) return;
  const merged = normalizeAnnouncementInput({
    title: input.title ?? existing.title,
    body: input.body ?? existing.body,
    targetDepartments: input.targetDepartments ?? toStringArray(existing.targetDepartments),
    targetRoutes: input.targetRoutes ?? toStringArray(existing.targetRoutes),
    isPinned: input.isPinned ?? existing.isPinned,
    isActive: input.isActive ?? existing.isActive,
    publishAt: input.publishAt ?? existing.publishAt,
    expiresAt: input.expiresAt === undefined ? existing.expiresAt : input.expiresAt,
  });
  const announcementKey = buildAnnouncementKey(merged);
  const prismaSameMinute = await prisma.announcement.findMany({
    where: {
      id: { not: id },
      publishAt: {
        gte: toMinute(merged.publishAt),
        lt: nextMinute(toMinute(merged.publishAt)),
      },
    },
    select: {
      title: true,
      body: true,
      targetDepartments: true,
      targetRoutes: true,
      publishAt: true,
    },
  });
  const hasRuntimeDuplicate = prismaSameMinute.some((row) =>
    isDuplicateAnnouncementContent(
      {
        title: row.title,
        body: row.body,
        targetDepartments: toStringArray(row.targetDepartments),
        targetRoutes: toStringArray(row.targetRoutes),
        publishAt: row.publishAt,
      },
      merged,
    ),
  );
  if (hasRuntimeDuplicate) {
    throw new Error("duplicate_announcement");
  }
  const duplicate = await prisma.announcement.findFirst({
    where: {
      id: { not: id },
      announcementKey,
      NOT: { announcementKey: null },
    },
    select: { id: true },
  });
  if (duplicate) {
    throw new Error("duplicate_announcement");
  }
  try {
    await prisma.announcement.update({
      where: { id },
      data: {
        ...input,
        publishAt: input.publishAt ? toMinute(input.publishAt) : undefined,
        announcementKey,
      },
    });
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2002") {
      throw new Error("duplicate_announcement");
    }
    throw error;
  }
}

export async function deleteAnnouncementById(id: string) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      await fsDeleteAnnouncement(id);
      return;
    } catch {
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  await prisma.announcement.delete({ where: { id } });
}

export async function listActiveUserProfilesForAudience(): Promise<{
  totalActiveUsers: number;
  profiles: ActiveUserProfile[];
}> {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      const profiles = await fsListActiveUserProfiles();
      logHybridPath({ store: "announcements", operation: "listAudienceProfiles", path: "firebase" });
      return { totalActiveUsers: profiles.length, profiles };
    } catch (error) {
      logHybridPath({
        store: "announcements",
        operation: "listAudienceProfiles",
        path: "prisma_fallback",
        reason: error instanceof Error ? error.message : "firebase_error",
      });
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const rows = await prisma.appUser.findMany({
    where: { isActive: true },
    select: { department: true, preferredRoutes: true },
  });
  const profiles = rows.map((u) => ({
    department: (u.department ?? "").trim().toLowerCase(),
    preferredRoutes: toStringArray(u.preferredRoutes)
      .map((v) => v.toLowerCase())
      .filter(Boolean),
  }));
  logHybridPath({
    store: "announcements",
    operation: "listAudienceProfiles",
    path: provider === "prisma" ? "prisma" : "prisma_fallback",
  });
  return { totalActiveUsers: rows.length, profiles };
}

export async function listLiveAnnouncementsForUserFilter(input: {
  email?: string;
  department?: string;
  routes?: string[];
}) {
  const email = (input.email ?? "").trim().toLowerCase();
  let department = (input.department ?? "").trim().toLowerCase();
  const routeSet = new Set(
    (input.routes ?? []).map((v) => v.trim().toLowerCase()).filter(Boolean),
  );

  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      const db = getFirebaseAdminFirestore();
      if (!db) throw new Error("firebase_unavailable");
      if (email) {
        const userByEmail = await db
          .collection("users")
          .where("email", "==", email)
          .limit(1)
          .get();
        if (!userByEmail.empty) {
          const userDoc = userByEmail.docs[0];
          const raw = userDoc.data() as Record<string, unknown>;
          if (!department) {
            department = String(raw.department ?? "").trim().toLowerCase();
          }
          const prefDoc = await db.collection("userPreferences").doc(userDoc.id).get();
          if (prefDoc.exists) {
            const prefRaw = prefDoc.data() as Record<string, unknown>;
            for (const r of toStringArray(prefRaw.savedRoutes)) {
              routeSet.add(r.toLowerCase());
            }
          }
        }
      }
      const rows = await fsListAdminAnnouncements();
      const now = Date.now();
      const filtered = rows
        .filter((r) => {
          if (!r.isActive) return false;
          if (r.publishAt.getTime() > now) return false;
          if (r.expiresAt && r.expiresAt.getTime() <= now) return false;
          const deptTargets = r.targetDepartments.map((v) => v.toLowerCase());
          const routeTargets = r.targetRoutes.map((v) => v.toLowerCase());
          const deptOk =
            deptTargets.length === 0 || (department ? deptTargets.includes(department) : false);
          const routeOk =
            routeTargets.length === 0 ||
            (routeSet.size > 0 ? routeTargets.some((v) => routeSet.has(v)) : false);
          return deptOk && routeOk;
        })
        .slice(0, 50);
      logHybridPath({ store: "announcements", operation: "listLiveForUser", path: "firebase" });
      return filtered;
    } catch (error) {
      logHybridPath({
        store: "announcements",
        operation: "listLiveForUser",
        path: "prisma_fallback",
        reason: error instanceof Error ? error.message : "firebase_error",
      });
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }

  if (email) {
    const user = await prisma.appUser.findUnique({
      where: { email },
      select: { department: true, preferredRoutes: true },
    });
    if (!department) {
      department = (user?.department ?? "").trim().toLowerCase();
    }
    const preferredRoutes = toStringArray(user?.preferredRoutes).map((v) => v.toLowerCase());
    for (const r of preferredRoutes) routeSet.add(r);
  }

  const now = new Date();
  const rows = await prisma.announcement.findMany({
    where: {
      isActive: true,
      publishAt: { lte: now },
      OR: [{ expiresAt: null }, { expiresAt: { gt: now } }],
    },
    orderBy: [{ isPinned: "desc" }, { publishAt: "desc" }],
    take: 50,
  });
  const filtered = rows
    .map(fromPrismaRow)
    .filter((r) => {
      const deptTargets = r.targetDepartments.map((v) => v.toLowerCase());
      const routeTargets = r.targetRoutes.map((v) => v.toLowerCase());
      const deptOk =
        deptTargets.length === 0 || (department ? deptTargets.includes(department) : false);
      const routeOk =
        routeTargets.length === 0 ||
        (routeSet.size > 0 ? routeTargets.some((v) => routeSet.has(v)) : false);
      return deptOk && routeOk;
    });
  logHybridPath({
    store: "announcements",
    operation: "listLiveForUser",
    path: provider === "prisma" ? "prisma" : "prisma_fallback",
  });
  return filtered;
}
