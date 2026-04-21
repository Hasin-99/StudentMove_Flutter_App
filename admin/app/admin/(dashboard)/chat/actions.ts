"use server";

import { revalidatePath } from "next/cache";
import { writeAuditLog } from "@/lib/audit-log";
import { sendChatMessage } from "@/lib/chat-store";
import { requireRole } from "@/lib/permissions";

async function guard() {
  await requireRole("transport_admin");
}

export async function sendChatReply(formData: FormData) {
  try {
    await guard();
    const email = String(formData.get("email") || "").trim().toLowerCase();
    const message = String(formData.get("message") || "").trim();
    if (!email || !email.includes("@") || !message) return;

    await sendChatMessage(email, message, "ADMIN");

    await writeAuditLog({
      action: "chat.reply",
      targetType: "chat",
      targetId: email,
      metadata: { length: message.length },
    });

    revalidatePath(`/admin/chat?email=${encodeURIComponent(email)}`);
  } catch (error) {
    console.error("[chat] sendChatReply failed", error);
  }
}
