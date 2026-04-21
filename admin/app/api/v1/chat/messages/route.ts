import { noContentWithCors, jsonWithCors } from "@/lib/cors";
import { apiError } from "@/lib/api-error";
import { withRequestContext } from "@/lib/request-context";
import { listChatConversation, sendChatMessage } from "@/lib/chat-store";

export async function OPTIONS(req: Request) {
  return withRequestContext(req, async () => noContentWithCors());
}

export async function GET(req: Request) {
  return withRequestContext(req, async () => {
    try {
      const { searchParams } = new URL(req.url);
      const email = (searchParams.get("email") ?? "").trim().toLowerCase();
      if (!email || !email.includes("@")) {
        return apiError({
          code: "invalid_payload",
          message: "A valid email is required.",
          status: 400,
        });
      }

      const rows = await listChatConversation(email);

      return jsonWithCors(rows);
    } catch (error) {
      console.error("[api/chat/messages] GET failed", error);
      return apiError({
        code: "service_unavailable",
        message: "Could not load chat messages right now.",
        status: 503,
      });
    }
  });
}

export async function POST(req: Request) {
  return withRequestContext(req, async () => {
    try {
      const body = (await req.json()) as {
        email?: string;
        message?: string;
        sender_role?: "USER" | "ADMIN";
      };
      const email = String(body?.email ?? "").trim().toLowerCase();
      const message = String(body?.message ?? "").trim();
      const senderRole = body?.sender_role === "ADMIN" ? "ADMIN" : "USER";

      if (!email || !email.includes("@") || !message) {
        return apiError({
          code: "invalid_payload",
          message: "Invalid chat message payload.",
          status: 400,
        });
      }

      const row = await sendChatMessage(email, message, senderRole);

      return jsonWithCors(row, { status: 201 });
    } catch (error) {
      console.error("[api/chat/messages] POST failed", error);
      return apiError({
        code: "service_unavailable",
        message: "Could not send chat message right now.",
        status: 503,
      });
    }
  });
}
