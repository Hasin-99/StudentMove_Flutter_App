import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { prisma } from "@/lib/prisma";
import { getFirebaseAdminFirestore } from "@/lib/firebase-admin";
import { logHybridPath } from "@/lib/runtime-diagnostics";

export type AuditRole = "SUPER_ADMIN" | "TRANSPORT_ADMIN" | "VIEWER";

export type AuditRow = {
  id: string;
  createdAt: Date;
  actorEmail: string;
  actorRole: AuditRole;
  action: string;
  targetType: string;
  targetId: string | null;
  metadata: unknown;
};

type QueryInput = {
  q: string;
  action: string;
  page: number;
  perPage: number;
};

function dataProvider() {
  return (process.env.ADMIN_DATA_PROVIDER ?? "hybrid").toLowerCase();
}

function firestoreEnabled() {
  return Boolean(process.env.FIREBASE_PROJECT_ID);
}

function asDate(value: unknown): Date {
  if (value instanceof Date) return value;
  if (value instanceof Timestamp) return value.toDate();
  const d = new Date(value as string);
  if (!Number.isNaN(d.getTime())) return d;
  return new Date();
}

function normalizeRole(input: unknown): AuditRole {
  const raw = String(input ?? "").toUpperCase();
  if (raw === "SUPER_ADMIN" || raw === "TRANSPORT_ADMIN") return raw;
  return "VIEWER";
}

function filterRows(rows: AuditRow[], q: string, action: string) {
  const qn = q.trim().toLowerCase();
  const an = action.trim();
  return rows.filter((r) => {
    if (an && r.action !== an) return false;
    if (!qn) return true;
    return [r.actorEmail, r.targetType, r.targetId ?? ""].join(" ").toLowerCase().includes(qn);
  });
}

async function fsReadAllAuditRows(): Promise<AuditRow[]> {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const snap = await db.collection("auditEvents").orderBy("createdAt", "desc").limit(5000).get();
  return snap.docs.map((doc) => {
    const d = doc.data();
    return {
      id: doc.id,
      createdAt: asDate(d.createdAt),
      actorEmail: String(d.actorEmail ?? ""),
      actorRole: normalizeRole(d.actorRole),
      action: String(d.action ?? ""),
      targetType: String(d.targetType ?? ""),
      targetId: d.targetId == null ? null : String(d.targetId),
      metadata: d.metadata ?? null,
    };
  });
}

async function fsWriteAuditLog(input: {
  actorEmail: string;
  actorRole: AuditRole;
  action: string;
  targetType: string;
  targetId?: string | null;
  metadata?: unknown;
}) {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  await db.collection("auditEvents").add({
    actorEmail: input.actorEmail,
    actorRole: input.actorRole,
    action: input.action,
    targetType: input.targetType,
    targetId: input.targetId ?? null,
    metadata: input.metadata ?? null,
    createdAt: FieldValue.serverTimestamp(),
  });
}

export async function writeAuditLogRecord(input: {
  actorEmail: string;
  actorRole: AuditRole;
  action: string;
  targetType: string;
  targetId?: string | null;
  metadata?: unknown;
}) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      await fsWriteAuditLog(input);
      logHybridPath({ store: "audit", operation: "writeAuditLogRecord", path: "firebase" });
      return;
    } catch (error) {
      logHybridPath({
        store: "audit",
        operation: "writeAuditLogRecord",
        path: "prisma_fallback",
        reason: error instanceof Error ? error.message : "firebase_error",
      });
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  await prisma.auditLog.create({
    data: {
      actorEmail: input.actorEmail,
      actorRole: input.actorRole,
      action: input.action,
      targetType: input.targetType,
      targetId: input.targetId ?? null,
      metadata: input.metadata as object | undefined,
    },
  });
  logHybridPath({
    store: "audit",
    operation: "writeAuditLogRecord",
    path: provider === "prisma" ? "prisma" : "prisma_fallback",
  });
}

export async function getAuditLogs(input: QueryInput) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      const allRows = filterRows(await fsReadAllAuditRows(), input.q, input.action);
      const total = allRows.length;
      const totalPages = Math.max(Math.ceil(total / input.perPage), 1);
      const currentPage = Math.min(Math.max(input.page, 1), totalPages);
      const start = (currentPage - 1) * input.perPage;
      const rows = allRows.slice(start, start + input.perPage);
      const actionSet = [...new Set(allRows.map((r) => r.action))].sort();
      logHybridPath({ store: "audit", operation: "getAuditLogs", path: "firebase" });
      return { rows, total, totalPages, currentPage, actions: actionSet };
    } catch (error) {
      logHybridPath({
        store: "audit",
        operation: "getAuditLogs",
        path: "prisma_fallback",
        reason: error instanceof Error ? error.message : "firebase_error",
      });
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }

  const where = {
    ...(input.action ? { action: input.action } : {}),
    ...(input.q
      ? {
          OR: [
            { actorEmail: { contains: input.q, mode: "insensitive" as const } },
            { targetType: { contains: input.q, mode: "insensitive" as const } },
            { targetId: { contains: input.q, mode: "insensitive" as const } },
          ],
        }
      : {}),
  };
  const total = await prisma.auditLog.count({ where });
  const totalPages = Math.max(Math.ceil(total / input.perPage), 1);
  const currentPage = Math.min(Math.max(input.page, 1), totalPages);
  const rows = (await prisma.auditLog.findMany({
    where,
    orderBy: { createdAt: "desc" },
    skip: (currentPage - 1) * input.perPage,
    take: input.perPage,
  })) as AuditRow[];
  const actions = (await prisma.auditLog.findMany({
    select: { action: true },
    distinct: ["action"],
    orderBy: { action: "asc" },
  })) as Array<{ action: string }>;
  logHybridPath({
    store: "audit",
    operation: "getAuditLogs",
    path: provider === "prisma" ? "prisma" : "prisma_fallback",
  });
  return {
    rows,
    total,
    totalPages,
    currentPage,
    actions: actions.map((a) => a.action),
  };
}

export async function getAuditLogsForExport(input: { q: string; action: string }) {
  const { rows } = await getAuditLogs({
    q: input.q,
    action: input.action,
    page: 1,
    perPage: 5000,
  });
  return rows;
}
