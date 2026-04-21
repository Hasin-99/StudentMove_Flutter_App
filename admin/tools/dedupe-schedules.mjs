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

function normalizeKey(input) {
  const clean = (v) =>
    String(v ?? "")
      .trim()
      .toLowerCase()
      .replace(/\s+/g, " ")
      .replace(/[^a-z0-9 ]+/g, "")
      .trim();
  return [
    String(input.routeId ?? "").trim(),
    String(input.busId ?? "").trim(),
    String(input.weekday ?? ""),
    clean(input.timeLabel),
    clean(input.dateLabel),
    clean(input.origin),
  ].join("::");
}

async function dedupePrismaSchedules() {
  const prisma = new PrismaClient();
  try {
    const schedules = await prisma.schedule.findMany({ orderBy: { createdAt: "asc" } });
    const byKey = new Map();
    for (const s of schedules) {
      const key = normalizeKey(s);
      if (!byKey.has(key)) byKey.set(key, []);
      byKey.get(key).push(s);
    }
    let removed = 0;
    for (const group of byKey.values()) {
      if (group.length <= 1) continue;
      const keep = group[0];
      for (const dup of group.slice(1)) {
        await prisma.schedule.delete({ where: { id: dup.id } });
        removed++;
      }
      await prisma.schedule.update({
        where: { id: keep.id },
        data: {
          timeLabel: keep.timeLabel.trim(),
          dateLabel: keep.dateLabel.trim(),
          origin: keep.origin.trim(),
        },
      });
    }
    console.log(`[dedupe-schedules] Prisma done. Removed duplicates: ${removed}`);
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

async function dedupeFirestoreSchedules() {
  const env = parseDotEnv(".env");
  const serviceAccount = parseServiceAccount(env.FIREBASE_SERVICE_ACCOUNT_JSON);
  if (!serviceAccount || !env.FIREBASE_PROJECT_ID) {
    console.log("[dedupe-schedules] Firestore skipped (missing Firebase credentials)");
    return;
  }
  const app = admin.initializeApp(
    {
      credential: admin.credential.cert(serviceAccount),
      projectId: env.FIREBASE_PROJECT_ID,
    },
    "dedupe-schedules",
  );
  const db = admin.firestore(app);
  const snap = await db.collection("schedules").get();
  const byKey = new Map();
  for (const doc of snap.docs) {
    const d = doc.data();
    const key = normalizeKey(d);
    if (!byKey.has(key)) byKey.set(key, []);
    byKey.get(key).push(doc);
  }
  let removed = 0;
  for (const [key, group] of byKey.entries()) {
    if (group.length <= 1) {
      await db.collection("scheduleUniqueLocks").doc(key).set(
        {
          scheduleId: group[0].id,
          scheduleKey: key,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      await group[0].ref.set({ scheduleKey: key }, { merge: true });
      continue;
    }
    const keep = group[0];
    const batch = db.batch();
    batch.set(keep.ref, { scheduleKey: key }, { merge: true });
    for (const dup of group.slice(1)) {
      batch.delete(dup.ref);
      removed++;
    }
    batch.set(
      db.collection("scheduleUniqueLocks").doc(key),
      {
        scheduleId: keep.id,
        scheduleKey: key,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    await batch.commit();
  }
  console.log(`[dedupe-schedules] Firestore done. Removed duplicates: ${removed}`);
}

await dedupePrismaSchedules();
await dedupeFirestoreSchedules();
console.log("[dedupe-schedules] Completed");
