import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { getFirebaseAdminFirestore } from "@/lib/firebase-admin";
import { prisma } from "@/lib/prisma";
import { logHybridPath } from "@/lib/runtime-diagnostics";

type SenderRole = "USER" | "ADMIN";

export type ChatMessageRecord = {
  id: string;
  userEmail: string;
  text: string;
  senderRole: SenderRole;
  createdAt: Date;
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

async function resolveUidByEmail(email: string): Promise<string | null> {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const snap = await db.collection("users").where("email", "==", email).limit(1).get();
  if (snap.empty) return null;
  return snap.docs[0].id;
}

async function fsGetMessages(email: string): Promise<ChatMessageRecord[]> {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const uid = await resolveUidByEmail(email);
  if (!uid) return [];
  const snap = await db
    .collection("chatRooms")
    .doc(uid)
    .collection("messages")
    .orderBy("createdAt", "asc")
    .limit(150)
    .get();
  return snap.docs.map((doc) => {
    const d = doc.data();
    return {
      id: doc.id,
      userEmail: email,
      text: String(d.text ?? ""),
      senderRole: String(d.senderRole ?? "USER").toUpperCase() === "ADMIN" ? "ADMIN" : "USER",
      createdAt: asDate(d.createdAt),
    };
  });
}

async function fsSendMessage(email: string, text: string, senderRole: SenderRole): Promise<ChatMessageRecord> {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const uid = await resolveUidByEmail(email);
  if (!uid) throw new Error("user_not_found");
  await db.collection("chatRooms").doc(uid).set(
    { ownerEmail: email, updatedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
  const ref = await db.collection("chatRooms").doc(uid).collection("messages").add({
    text,
    senderRole: senderRole === "ADMIN" ? "admin" : "user",
    createdAt: FieldValue.serverTimestamp(),
  });
  await db.collection("users").doc(uid).set(
    { lastSeenAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
  return {
    id: ref.id,
    userEmail: email,
    text,
    senderRole,
    createdAt: new Date(),
  };
}

async function fsListInbox() {
  const db = getFirebaseAdminFirestore();
  if (!db) throw new Error("firebase_unavailable");
  const usersSnap = await db.collection("users").get();
  const rows = await Promise.all(
    usersSnap.docs.map(async (u) => {
      const email = String(u.data().email ?? "").trim().toLowerCase();
      if (!email) return null;
      const latest = await db
        .collection("chatRooms")
        .doc(u.id)
        .collection("messages")
        .orderBy("createdAt", "desc")
        .limit(1)
        .get();
      if (latest.empty) return null;
      const d = latest.docs[0].data();
      return {
        userEmail: email,
        createdAt: asDate(d.createdAt),
        text: String(d.text ?? ""),
      };
    }),
  );
  return rows
    .filter((r): r is { userEmail: string; createdAt: Date; text: string } => Boolean(r))
    .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
    .slice(0, 80);
}

export async function listChatInbox() {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      const rows = await fsListInbox();
      logHybridPath({ store: "chat", operation: "listChatInbox", path: "firebase" });
      return rows;
    } catch (error) {
      logHybridPath({
        store: "chat",
        operation: "listChatInbox",
        path: "prisma_fallback",
        reason: error instanceof Error ? error.message : "firebase_error",
      });
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  logHybridPath({
    store: "chat",
    operation: "listChatInbox",
    path: provider === "prisma" ? "prisma" : "prisma_fallback",
  });
  return prisma.chatMessage.findMany({
    distinct: ["userEmail"],
    orderBy: { createdAt: "desc" },
    select: { userEmail: true, createdAt: true, text: true },
    take: 80,
  });
}

export async function listChatConversation(email: string) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      const rows = await fsGetMessages(email);
      logHybridPath({ store: "chat", operation: "listChatConversation", path: "firebase" });
      return rows;
    } catch (error) {
      logHybridPath({
        store: "chat",
        operation: "listChatConversation",
        path: "prisma_fallback",
        reason: error instanceof Error ? error.message : "firebase_error",
      });
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  logHybridPath({
    store: "chat",
    operation: "listChatConversation",
    path: provider === "prisma" ? "prisma" : "prisma_fallback",
  });
  return prisma.chatMessage.findMany({
    where: { userEmail: email },
    orderBy: { createdAt: "asc" },
    take: 200,
  });
}

export async function sendChatMessage(email: string, message: string, senderRole: SenderRole) {
  const provider = dataProvider();
  if (provider !== "prisma" && firestoreEnabled()) {
    try {
      const row = await fsSendMessage(email, message, senderRole);
      logHybridPath({ store: "chat", operation: "sendChatMessage", path: "firebase" });
      return row;
    } catch (error) {
      logHybridPath({
        store: "chat",
        operation: "sendChatMessage",
        path: "prisma_fallback",
        reason: error instanceof Error ? error.message : "firebase_error",
      });
      if (provider === "firebase") throw new Error("firebase_unavailable");
    }
  }
  const row = await prisma.chatMessage.create({
    data: { userEmail: email, text: message, senderRole },
  });
  await prisma.appUser.updateMany({
    where: { email },
    data: { lastSeenAt: new Date() },
  });
  logHybridPath({
    store: "chat",
    operation: "sendChatMessage",
    path: provider === "prisma" ? "prisma" : "prisma_fallback",
  });
  return row;
}
