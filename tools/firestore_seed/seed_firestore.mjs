import fs from 'node:fs/promises';
import path from 'node:path';
import admin from 'firebase-admin';

const projectId = process.env.FIREBASE_PROJECT_ID || 'studentmove-dev';
const useEmulator = process.env.USE_FIRESTORE_EMULATOR === 'true';

if (useEmulator && !process.env.FIRESTORE_EMULATOR_HOST) {
  process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
}

if (!admin.apps.length) {
  admin.initializeApp({ projectId });
}

const db = admin.firestore();
const now = admin.firestore.FieldValue.serverTimestamp();

const seedPath = path.resolve(process.cwd(), 'seed_data.json');
const seedRaw = await fs.readFile(seedPath, 'utf8');
const seed = JSON.parse(seedRaw);

async function writeCollection(collection, docs, transform = (doc) => doc) {
  for (const entry of docs) {
    const id = entry.id;
    if (!id) continue;
    const payload = transform(entry);
    await db.collection(collection).doc(id).set(payload, { merge: true });
    console.log(`seeded ${collection}/${id}`);
  }
}

await writeCollection('routes', seed.routes, (entry) => ({
  name: entry.name,
  stops: entry.stops ?? [],
  active: entry.active !== false,
  updatedAt: now,
}));

await writeCollection('schedules', seed.schedules, (entry) => ({
  routeName: entry.routeName,
  dayIndex: Number(entry.dayIndex ?? 0),
  timeLabel: entry.timeLabel,
  dateLabel: entry.dateLabel,
  origin: entry.origin,
  busCode: entry.busCode,
  whiteboardNote: entry.whiteboardNote ?? '',
  universityTags: entry.universityTags ?? [],
  updatedAt: now,
}));

await writeCollection('announcements', seed.announcements, (entry) => ({
  title: entry.title,
  body: entry.body,
  isPinned: entry.isPinned === true,
  isVisible: entry.isVisible !== false,
  routes: entry.routes ?? [],
  departments: entry.departments ?? [],
  publishAt: now,
  updatedAt: now,
}));

await writeCollection('liveBuses', seed.liveBuses, (entry) => ({
  busCode: entry.busCode,
  lat: Number(entry.lat ?? 0),
  lng: Number(entry.lng ?? 0),
  heading: Number(entry.heading ?? 0),
  speedKmph: Number(entry.speedKmph ?? 0),
  updatedAt: now,
}));

console.log(`Firestore seed completed for project: ${projectId}`);
