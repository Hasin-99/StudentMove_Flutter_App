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

function normalizeText(value) {
  return String(value ?? "")
    .trim()
    .toLowerCase()
    .replace(/\s+/g, " ")
    .replace(/[^a-z0-9 ]+/g, "")
    .trim();
}

function normalizeTargets(values) {
  if (!Array.isArray(values)) return "";
  return values
    .map((v) => normalizeText(v))
    .filter(Boolean)
    .sort()
    .join("|");
}

function toMinuteIso(value) {
  const d = new Date(value ?? Date.now());
  d.setSeconds(0, 0);
  return d.toISOString();
}

function announcementKey(raw) {
  return [
    normalizeText(raw.title),
    normalizeText(raw.body),
    normalizeTargets(raw.targetDepartments),
    normalizeTargets(raw.targetRoutes),
    toMinuteIso(raw.publishAt),
  ].join("::");
}

async function dedupePrismaAnnouncements() {
  const prisma = new PrismaClient();
  try {
    const rows = await prisma.announcement.findMany({ orderBy: { createdAt: "asc" } });
    const grouped = new Map();
    for (const row of rows) {
      const key = announcementKey(row);
      if (!grouped.has(key)) grouped.set(key, []);
      grouped.get(key).push(row);
    }
    let removed = 0;
    let keyed = 0;
    for (const [key, items] of grouped.entries()) {
      const keep = items[0];
      await prisma.announcement.update({
        where: { id: keep.id },
        data: { announcementKey: key, publishAt: new Date(toMinuteIso(keep.publishAt)) },
      });
      keyed++;
      for (const dup of items.slice(1)) {
        await prisma.announcement.delete({ where: { id: dup.id } });
        removed++;
      }
    }
    console.log(`[dedupe-announcements] Prisma done. Keyed: ${keyed}, removed: ${removed}`);
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

async function dedupeFirestoreAnnouncements() {
  const env = parseDotEnv(".env");
  const serviceAccount = parseServiceAccount(env.FIREBASE_SERVICE_ACCOUNT_JSON);
  if (!serviceAccount || !env.FIREBASE_PROJECT_ID) {
    console.log("[dedupe-announcements] Firestore skipped (missing Firebase credentials)");
    return;
  }
  const app = admin.initializeApp(
    {
      credential: admin.credential.cert(serviceAccount),
      projectId: env.FIREBASE_PROJECT_ID,
    },
    "dedupe-announcements",
  );
  const db = admin.firestore(app);
  const snap = await db.collection("announcements").get();
  const grouped = new Map();
  for (const doc of snap.docs) {
    const key = announcementKey(doc.data());
    if (!grouped.has(key)) grouped.set(key, []);
    grouped.get(key).push(doc);
  }
  let removed = 0;
  let keyed = 0;
  for (const [key, docs] of grouped.entries()) {
    const keep = docs[0];
    const batch = db.batch();
    batch.set(
      keep.ref,
      {
        announcementKey: key,
        publishAt: new Date(toMinuteIso(keep.data().publishAt)),
      },
      { merge: true },
    );
    keyed++;
    for (const dup of docs.slice(1)) {
      batch.delete(dup.ref);
      removed++;
    }
    batch.set(
      db.collection("announcementUniqueLocks").doc(key),
      {
        announcementId: keep.id,
        announcementKey: key,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    await batch.commit();
  }
  console.log(`[dedupe-announcements] Firestore done. Keyed: ${keyed}, removed: ${removed}`);
}

await dedupePrismaAnnouncements();
await dedupeFirestoreAnnouncements();
console.log("[dedupe-announcements] Completed");
