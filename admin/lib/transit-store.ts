import { FieldValue } from "firebase-admin/firestore";
import { Prisma } from "@prisma/client";
import { getFirebaseAdminFirestore } from "@/lib/firebase-admin";
import { prisma } from "@/lib/prisma";
import { logHybridPath } from "@/lib/runtime-diagnostics";

type RouteRecord = {
  id: string;
  name: string;
  code: string | null;
  scheduleCount: number;
};

type BusRecord = {
  id: string;
  code: string;
  scheduleCount: number;
};

type ScheduleRecord = {
  id: string;
  routeId: string;
  busId: string;
  weekday: number;
  timeLabel: string;
  dateLabel: string;
  origin: string;
  whiteboardNote: string | null;
  universityTags: string[];
  routeName: string;
  busCode: string;
};

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

function normalizeRouteName(name: string) {
  return name
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function normalizeScheduleKey(input: {
  routeId: string;
  busId: string;
  weekday: number;
  timeLabel: string;
  dateLabel: string;
  origin: string;
}) {
  const clean = (v: string) =>
    v
      .trim()
      .toLowerCase()
      .replace(/\s+/g, " ")
      .replace(/[^a-z0-9 ]+/g, "")
      .trim();
  return [
    input.routeId.trim(),
    input.busId.trim(),
    String(input.weekday),
    clean(input.timeLabel),
    clean(input.dateLabel),
    clean(input.origin),
  ].join("::");
}

async function fsListRoutes(): Promise<RouteRecord[]> {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const [routesSnap, schedulesSnap] = await Promise.all([
    db.collection("routes").get(),
    db.collection("schedules").get(),
  ]);
  const countByRoute = new Map<string, number>();
  for (const s of schedulesSnap.docs) {
    const routeId = String(s.data().routeId ?? "");
    if (!routeId) continue;
    countByRoute.set(routeId, (countByRoute.get(routeId) ?? 0) + 1);
  }
  return routesSnap.docs
    .map((doc) => {
      const d = doc.data();
      return {
        id: doc.id,
        name: String(d.name ?? d.routeName ?? ""),
        code: d.code == null ? null : String(d.code),
        scheduleCount: countByRoute.get(doc.id) ?? 0,
      };
    })
    .sort((a, b) => a.name.localeCompare(b.name));
}

async function fsCreateRoute(name: string, code: string | null): Promise<RouteRecord> {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const normalizedName = normalizeRouteName(name);
  if (!normalizedName) throw new Error("invalid_route_name");
  const lockRef = db.collection("routeUniqueLocks").doc(normalizedName);
  const routeRef = db.collection("routes").doc();
  await db.runTransaction(async (tx) => {
    const lockDoc = await tx.get(lockRef);
    if (lockDoc.exists) {
      throw new Error("duplicate_route");
    }
    tx.set(routeRef, {
      name,
      code,
      normalizedName,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(lockRef, {
      routeId: routeRef.id,
      normalizedName,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  return { id: routeRef.id, name, code, scheduleCount: 0 };
}

async function fsGetRoute(id: string): Promise<RouteRecord | null> {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const [doc, scheduleSnap] = await Promise.all([
    db.collection("routes").doc(id).get(),
    db.collection("schedules").where("routeId", "==", id).get(),
  ]);
  if (!doc.exists) return null;
  const d = doc.data() as Record<string, unknown>;
  return {
    id: doc.id,
    name: String(d.name ?? d.routeName ?? ""),
    code: d.code == null ? null : String(d.code),
    scheduleCount: scheduleSnap.size,
  };
}

async function fsDeleteRoute(id: string) {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  await db.collection("routes").doc(id).delete();
}

async function fsListBuses(): Promise<BusRecord[]> {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const [busesSnap, schedulesSnap] = await Promise.all([
    db.collection("buses").get(),
    db.collection("schedules").get(),
  ]);
  const countByBus = new Map<string, number>();
  for (const s of schedulesSnap.docs) {
    const busId = String(s.data().busId ?? "");
    if (!busId) continue;
    countByBus.set(busId, (countByBus.get(busId) ?? 0) + 1);
  }
  return busesSnap.docs
    .map((doc) => {
      const d = doc.data();
      return {
        id: doc.id,
        code: String(d.code ?? ""),
        scheduleCount: countByBus.get(doc.id) ?? 0,
      };
    })
    .sort((a, b) => a.code.localeCompare(b.code));
}

async function fsCreateBus(code: string): Promise<BusRecord> {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const ref = db.collection("buses").doc();
  await ref.set({
    code,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return { id: ref.id, code, scheduleCount: 0 };
}

async function fsGetBus(id: string): Promise<BusRecord | null> {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const [doc, scheduleSnap] = await Promise.all([
    db.collection("buses").doc(id).get(),
    db.collection("schedules").where("busId", "==", id).get(),
  ]);
  if (!doc.exists) return null;
  const d = doc.data() as Record<string, unknown>;
  return {
    id: doc.id,
    code: String(d.code ?? ""),
    scheduleCount: scheduleSnap.size,
  };
}

async function fsDeleteBus(id: string) {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  await db.collection("buses").doc(id).delete();
}

async function fsListSchedules(): Promise<ScheduleRecord[]> {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const [routesSnap, busesSnap, schedulesSnap] = await Promise.all([
    db.collection("routes").get(),
    db.collection("buses").get(),
    db.collection("schedules").get(),
  ]);
  const routeNameById = new Map<string, string>();
  for (const r of routesSnap.docs) {
    const d = r.data();
    routeNameById.set(r.id, String(d.name ?? d.routeName ?? ""));
  }
  const busCodeById = new Map<string, string>();
  for (const b of busesSnap.docs) {
    busCodeById.set(b.id, String(b.data().code ?? ""));
  }
  return schedulesSnap.docs
    .map((doc) => {
      const d = doc.data();
      const routeId = String(d.routeId ?? "");
      const busId = String(d.busId ?? "");
      return {
        id: doc.id,
        routeId,
        busId,
        weekday: Number(d.weekday ?? 0),
        timeLabel: String(d.timeLabel ?? ""),
        dateLabel: String(d.dateLabel ?? ""),
        origin: String(d.origin ?? ""),
        whiteboardNote: d.whiteboardNote == null ? null : String(d.whiteboardNote),
        universityTags: asStringArray(d.universityTags),
        routeName: routeNameById.get(routeId) ?? "",
        busCode: busCodeById.get(busId) ?? "",
      };
    })
    .sort((a, b) => {
      const routeCmp = a.routeName.localeCompare(b.routeName);
      if (routeCmp !== 0) return routeCmp;
      if (a.weekday !== b.weekday) return a.weekday - b.weekday;
      return a.timeLabel.localeCompare(b.timeLabel);
    });
}

async function fsCreateSchedule(input: {
  routeId: string;
  busId: string;
  weekday: number;
  timeLabel: string;
  dateLabel: string;
  origin: string;
  whiteboardNote: string | null;
  universityTags: string[];
}) {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const scheduleKey = normalizeScheduleKey(input);
  if (!scheduleKey) throw new Error("invalid_schedule");
  const route = await db.collection("routes").doc(input.routeId).get();
  const bus = await db.collection("buses").doc(input.busId).get();
  const existing = await db
    .collection("schedules")
    .where("routeId", "==", input.routeId)
    .where("busId", "==", input.busId)
    .where("weekday", "==", input.weekday)
    .where("timeLabel", "==", input.timeLabel)
    .where("dateLabel", "==", input.dateLabel)
    .where("origin", "==", input.origin)
    .limit(1)
    .get();
  if (!existing.empty) {
    throw new Error("duplicate_schedule");
  }
  const ref = db.collection("schedules").doc();
  const lockRef = db.collection("scheduleUniqueLocks").doc(scheduleKey);
  await db.runTransaction(async (tx) => {
    const lockDoc = await tx.get(lockRef);
    if (lockDoc.exists) throw new Error("duplicate_schedule");
    tx.set(ref, {
      ...input,
      scheduleKey,
      dayIndex: input.weekday,
      routeName: String(route.data()?.name ?? route.data()?.routeName ?? ""),
      busCode: String(bus.data()?.code ?? ""),
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(lockRef, {
      scheduleId: ref.id,
      scheduleKey,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  return { id: ref.id };
}

async function fsGetSchedule(id: string): Promise<ScheduleRecord | null> {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const doc = await db.collection("schedules").doc(id).get();
  if (!doc.exists) return null;
  const d = doc.data() as Record<string, unknown>;
  return {
    id: doc.id,
    routeId: String(d.routeId ?? ""),
    busId: String(d.busId ?? ""),
    weekday: Number(d.weekday ?? 0),
    timeLabel: String(d.timeLabel ?? ""),
    dateLabel: String(d.dateLabel ?? ""),
    origin: String(d.origin ?? ""),
    whiteboardNote: d.whiteboardNote == null ? null : String(d.whiteboardNote),
    universityTags: asStringArray(d.universityTags),
    routeName: String(d.routeName ?? ""),
    busCode: String(d.busCode ?? ""),
  };
}

async function fsDeleteSchedule(id: string) {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const doc = await db.collection("schedules").doc(id).get();
  const scheduleKey = String(doc.data()?.scheduleKey ?? "");
  const batch = db.batch();
  batch.delete(db.collection("schedules").doc(id));
  if (scheduleKey) {
    batch.delete(db.collection("scheduleUniqueLocks").doc(scheduleKey));
  }
  await batch.commit();
}

export async function listRoutesForAdmin() {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      const rows = await fsListRoutes();
      logHybridPath({ store: "transit", operation: "listRoutesForAdmin", path: "firebase" });
      return rows;
    } catch (error) {
      logHybridPath({
        store: "transit",
        operation: "listRoutesForAdmin",
        path: "prisma_fallback",
        reason: error instanceof Error ? error.message : "firebase_error",
      });
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const routes = await prisma.busRoute.findMany({
    orderBy: { name: "asc" },
    include: { _count: { select: { schedules: true } } },
  });
  logHybridPath({
    store: "transit",
    operation: "listRoutesForAdmin",
    path: provider === "prisma" ? "prisma" : "prisma_fallback",
  });
  return routes.map((r) => ({
    id: r.id,
    name: r.name,
    code: r.code,
    scheduleCount: r._count.schedules,
  }));
}

export async function createRouteRecord(name: string, code: string | null) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      return await fsCreateRoute(name, code);
    } catch (error) {
      if (error instanceof Error && error.message === "duplicate_route") {
        throw error;
      }
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const normalizedName = normalizeRouteName(name);
  if (!normalizedName) throw new Error("invalid_route_name");
  try {
    const route = await prisma.busRoute.create({ data: { name, code, normalizedName } });
    return { id: route.id, name: route.name, code: route.code, scheduleCount: 0 };
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2002") {
      throw new Error("duplicate_route");
    }
    throw error;
  }
}

export async function getRouteById(id: string) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      return await fsGetRoute(id);
    } catch {
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const route = await prisma.busRoute.findUnique({
    where: { id },
    include: { _count: { select: { schedules: true } } },
  });
  if (!route) return null;
  return { id: route.id, name: route.name, code: route.code, scheduleCount: route._count.schedules };
}

export async function deleteRouteById(id: string) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      await fsDeleteRoute(id);
      return;
    } catch {
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  await prisma.busRoute.delete({ where: { id } });
}

export async function listBusesForAdmin() {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      const rows = await fsListBuses();
      logHybridPath({ store: "transit", operation: "listBusesForAdmin", path: "firebase" });
      return rows;
    } catch (error) {
      logHybridPath({
        store: "transit",
        operation: "listBusesForAdmin",
        path: "prisma_fallback",
        reason: error instanceof Error ? error.message : "firebase_error",
      });
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const buses = await prisma.bus.findMany({
    orderBy: { code: "asc" },
    include: { _count: { select: { schedules: true } } },
  });
  logHybridPath({
    store: "transit",
    operation: "listBusesForAdmin",
    path: provider === "prisma" ? "prisma" : "prisma_fallback",
  });
  return buses.map((b) => ({ id: b.id, code: b.code, scheduleCount: b._count.schedules }));
}

export async function createBusRecord(code: string) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      return await fsCreateBus(code);
    } catch {
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const bus = await prisma.bus.create({ data: { code } });
  return { id: bus.id, code: bus.code, scheduleCount: 0 };
}

export async function getBusById(id: string) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      return await fsGetBus(id);
    } catch {
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const bus = await prisma.bus.findUnique({
    where: { id },
    include: { _count: { select: { schedules: true } } },
  });
  if (!bus) return null;
  return { id: bus.id, code: bus.code, scheduleCount: bus._count.schedules };
}

export async function deleteBusById(id: string) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      await fsDeleteBus(id);
      return;
    } catch {
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  await prisma.bus.delete({ where: { id } });
}

export async function listSchedulesForAdmin() {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      const rows = await fsListSchedules();
      logHybridPath({ store: "transit", operation: "listSchedulesForAdmin", path: "firebase" });
      return rows;
    } catch (error) {
      logHybridPath({
        store: "transit",
        operation: "listSchedulesForAdmin",
        path: "prisma_fallback",
        reason: error instanceof Error ? error.message : "firebase_error",
      });
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const schedules = await prisma.schedule.findMany({
    include: { route: true, bus: true },
    orderBy: [{ route: { name: "asc" } }, { weekday: "asc" }, { timeLabel: "asc" }],
  });
  logHybridPath({
    store: "transit",
    operation: "listSchedulesForAdmin",
    path: provider === "prisma" ? "prisma" : "prisma_fallback",
  });
  return schedules.map((s) => ({
    id: s.id,
    routeId: s.routeId,
    busId: s.busId,
    weekday: s.weekday,
    timeLabel: s.timeLabel,
    dateLabel: s.dateLabel,
    origin: s.origin,
    whiteboardNote: s.whiteboardNote,
    universityTags: asStringArray(s.universityTags),
    routeName: s.route.name,
    busCode: s.bus.code,
  }));
}

export async function createScheduleRecord(input: {
  routeId: string;
  busId: string;
  weekday: number;
  timeLabel: string;
  dateLabel: string;
  origin: string;
  whiteboardNote: string | null;
  universityTags: string[];
}) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      return await fsCreateSchedule(input);
    } catch (error) {
      if (error instanceof Error && error.message === "duplicate_schedule") {
        throw error;
      }
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  try {
    const schedule = await prisma.schedule.create({ data: input });
    return { id: schedule.id };
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2002") {
      throw new Error("duplicate_schedule");
    }
    throw error;
  }
}

export async function getScheduleById(id: string) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      return await fsGetSchedule(id);
    } catch {
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const schedule = await prisma.schedule.findUnique({ where: { id } });
  if (!schedule) return null;
  return {
    id: schedule.id,
    routeId: schedule.routeId,
    busId: schedule.busId,
    weekday: schedule.weekday,
    timeLabel: schedule.timeLabel,
    dateLabel: schedule.dateLabel,
    origin: schedule.origin,
    whiteboardNote: schedule.whiteboardNote,
    universityTags: asStringArray(schedule.universityTags),
    routeName: "",
    busCode: "",
  };
}

export async function deleteScheduleById(id: string) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      await fsDeleteSchedule(id);
      return;
    } catch {
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  await prisma.schedule.delete({ where: { id } });
}

export async function listBusesForLive(limit = 12) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      const buses = await fsListBuses();
      logHybridPath({ store: "transit", operation: "listBusesForLive", path: "firebase" });
      return buses.slice(0, limit).map((b) => ({ id: b.id, code: b.code }));
    } catch (error) {
      logHybridPath({
        store: "transit",
        operation: "listBusesForLive",
        path: "prisma_fallback",
        reason: error instanceof Error ? error.message : "firebase_error",
      });
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  logHybridPath({
    store: "transit",
    operation: "listBusesForLive",
    path: provider === "prisma" ? "prisma" : "prisma_fallback",
  });
  return prisma.bus.findMany({ orderBy: { code: "asc" }, take: limit, select: { id: true, code: true } });
}

export async function getTransitCounts() {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      const [routes, buses, schedules] = await Promise.all([
        fsListRoutes(),
        fsListBuses(),
        fsListSchedules(),
      ]);
      logHybridPath({ store: "transit", operation: "getTransitCounts", path: "firebase" });
      return {
        routes: routes.length,
        buses: buses.length,
        schedules: schedules.length,
      };
    } catch (error) {
      logHybridPath({
        store: "transit",
        operation: "getTransitCounts",
        path: "prisma_fallback",
        reason: error instanceof Error ? error.message : "firebase_error",
      });
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const [routes, buses, schedules] = await Promise.all([
    prisma.busRoute.count(),
    prisma.bus.count(),
    prisma.schedule.count(),
  ]);
  logHybridPath({
    store: "transit",
    operation: "getTransitCounts",
    path: provider === "prisma" ? "prisma" : "prisma_fallback",
  });
  return { routes, buses, schedules };
}

export function scheduleToFlutterSlot(s: ScheduleRecord) {
  return {
    route_name: s.routeName,
    day_index: s.weekday,
    time: s.timeLabel,
    date: s.dateLabel,
    bus_code: s.busCode,
    origin: s.origin,
    whiteboard_note: s.whiteboardNote ?? "",
    university_tags: s.universityTags,
  };
}
