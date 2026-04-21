import fs from "node:fs";
import { PrismaClient } from "@prisma/client";
import admin from "firebase-admin";

function parseDotEnv(path) {
  const out = {};
  const raw = fs.readFileSync(path, "utf8");
  for (const line of raw.split(/\r?\n/)) {
    const t = line.trim();
    if (!t || t.startsWith("#")) continue;
    const i = t.indexOf("=");
    if (i < 0) continue;
    const k = t.slice(0, i).trim();
    let v = t.slice(i + 1).trim();
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
      v = v.slice(1, -1);
    }
    out[k] = v;
  }
  return out;
}

function normalizeRouteName(name) {
  return String(name ?? "")
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

async function dedupePrismaRoutes() {
  const prisma = new PrismaClient();
  try {
    const routes = await prisma.busRoute.findMany({
      include: { _count: { select: { schedules: true } } },
      orderBy: { createdAt: "asc" },
    });
    const byKey = new Map();
    for (const r of routes) {
      const key = normalizeRouteName(r.name);
      if (!key) continue;
      if (!byKey.has(key)) byKey.set(key, []);
      byKey.get(key).push(r);
    }
    let removed = 0;
    for (const [key, group] of byKey.entries()) {
      if (group.length <= 1) continue;
      group.sort((a, b) => b._count.schedules - a._count.schedules || a.createdAt - b.createdAt);
      const keep = group[0];
      for (const dup of group.slice(1)) {
        await prisma.schedule.updateMany({ where: { routeId: dup.id }, data: { routeId: keep.id } });
        await prisma.busRoute.delete({ where: { id: dup.id } });
        removed++;
      }
      await prisma.busRoute.update({ where: { id: keep.id }, data: { normalizedName: key } });
    }
    const fresh = await prisma.busRoute.findMany();
    for (const r of fresh) {
      const key = normalizeRouteName(r.name) || `route-${r.id}`;
      await prisma.busRoute.update({ where: { id: r.id }, data: { normalizedName: key } });
    }
    console.log(`[dedupe-routes] Prisma done. Removed duplicates: ${removed}`);
  } finally {
    await prisma.$disconnect();
  }
}

function parseServiceAccount(raw) {
  if (!raw) return null;
  const attempts = [raw, raw.replace(/\\"/g, '"')];
  for (const candidate of attempts) {
    try {
      const parsed = JSON.parse(candidate);
      if (typeof parsed.private_key === "string") {
        parsed.private_key = parsed.private_key.replace(/\\n/g, "\n");
      }
      return parsed;
    } catch {}
  }
  return null;
}

async function dedupeFirestoreRoutes() {
  const env = parseDotEnv(".env");
  const serviceAccount = parseServiceAccount(env.FIREBASE_SERVICE_ACCOUNT_JSON);
  if (!serviceAccount || !env.FIREBASE_PROJECT_ID) {
    console.log("[dedupe-routes] Firestore skipped (missing Firebase credentials)");
    return;
  }
  const app = admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: env.FIREBASE_PROJECT_ID,
  }, "dedupe-routes");
  const db = admin.firestore(app);
  const routesSnap = await db.collection("routes").get();
  const byKey = new Map();
  for (const doc of routesSnap.docs) {
    const name = String(doc.data().name ?? doc.data().routeName ?? "");
    const key = normalizeRouteName(name);
    if (!key) continue;
    if (!byKey.has(key)) byKey.set(key, []);
    byKey.get(key).push(doc);
  }
  let removed = 0;
  for (const [key, group] of byKey.entries()) {
    if (group.length <= 1) {
      await db.collection("routeUniqueLocks").doc(key).set(
        { routeId: group[0].id, normalizedName: key, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
        { merge: true },
      );
      await group[0].ref.set({ normalizedName: key }, { merge: true });
      continue;
    }
    const keep = group[0];
    for (const dup of group.slice(1)) {
      const schedules = await db.collection("schedules").where("routeId", "==", dup.id).get();
      const batch = db.batch();
      for (const s of schedules.docs) {
        batch.set(
          s.ref,
          {
            routeId: keep.id,
            routeName: String(keep.data().name ?? keep.data().routeName ?? ""),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }
      batch.delete(dup.ref);
      await batch.commit();
      removed++;
    }
    await keep.ref.set({ normalizedName: key }, { merge: true });
    await db.collection("routeUniqueLocks").doc(key).set(
      { routeId: keep.id, normalizedName: key, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true },
    );
  }
  console.log(`[dedupe-routes] Firestore done. Removed duplicates: ${removed}`);
}

await dedupePrismaRoutes();
await dedupeFirestoreRoutes();
console.log("[dedupe-routes] Completed");
