import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

const ADMIN_ROLES = new Set(["admin", "super_admin", "transport_admin"]);

function requireAdmin(auth: { uid: string; token: Record<string, unknown> } | undefined): string {
  if (!auth) {
    throw new HttpsError("unauthenticated", "Unauthenticated");
  }
  const role = String(auth.token.role ?? "");
  if (!ADMIN_ROLES.has(role)) {
    throw new HttpsError("permission-denied", "Permission denied");
  }
  return auth.uid;
}

async function enforceRateLimit(uid: string, key: string, seconds: number): Promise<void> {
  const ref = db.collection("rateLimits").doc(`${uid}_${key}`);
  const snap = await ref.get();
  const now = Date.now();
  if (snap.exists) {
    const last = Number(snap.data()?.lastAtMs ?? 0);
    if (last > 0 && now - last < seconds * 1000) {
      throw new HttpsError("resource-exhausted", "Rate limit exceeded");
    }
  }
  await ref.set({ lastAtMs: now }, { merge: true });
}

export const announce = onCall(async (request) => {
  const uid = requireAdmin(request.auth);
  await enforceRateLimit(uid, "announce", 10);

  const data = request.data as {
    title?: string;
    body?: string;
    routes?: string[];
    departments?: string[];
    isPinned?: boolean;
  };

  const title = (data.title ?? "").trim();
  const body = (data.body ?? "").trim();
  if (!title || !body) {
    throw new HttpsError("invalid-argument", "Title and body are required");
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  const ref = await db.collection("announcements").add({
    title,
    body,
    routes: Array.isArray(data.routes) ? data.routes : [],
    departments: Array.isArray(data.departments) ? data.departments : [],
    isPinned: data.isPinned == true,
    publishAt: now,
    createdAt: now,
    createdBy: uid,
  });

  await db.collection("auditEvents").add({
    actorUid: uid,
    action: "announcement.create",
    targetId: ref.id,
    at: now,
  });

  await messaging.send({
    topic: "all-users",
    notification: {
      title,
      body,
    },
    data: {
      announcementId: ref.id,
    },
  });

  return { ok: true, id: ref.id };
});

export const upsertLiveBus = onCall(async (request) => {
  const uid = requireAdmin(request.auth);
  await enforceRateLimit(uid, "upsertLiveBus", 1);

  const data = request.data as {
    busId?: string;
    busCode?: string;
    lat?: number;
    lng?: number;
    heading?: number;
    speedKmph?: number;
  };
  const busId = (data.busId ?? "").trim();
  const busCode = (data.busCode ?? "").trim();
  if (!busId || !busCode) {
    throw new HttpsError("invalid-argument", "busId and busCode are required");
  }

  await db.collection("liveBuses").doc(busId).set(
    {
      busCode,
      lat: Number(data.lat ?? 0),
      lng: Number(data.lng ?? 0),
      heading: Number(data.heading ?? 0),
      speedKmph: Number(data.speedKmph ?? 0),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  await db.collection("auditEvents").add({
    actorUid: uid,
    action: "liveBus.upsert",
    targetId: busId,
    at: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { ok: true };
});
