import { writeAuditLogRecord } from "@/lib/audit-store";
import { getSession } from "@/lib/session";

type AuditInput = {
  action: string;
  targetType: string;
  targetId?: string | null;
  metadata?: unknown;
};

export async function writeAuditLog(input: AuditInput) {
  const session = await getSession();
  if (!session.isAdmin || !session.email) return;

  const role = (session.role ?? "viewer").toUpperCase();
  const actorRole =
    role === "SUPER_ADMIN" || role === "TRANSPORT_ADMIN" || role === "VIEWER"
      ? role
      : "VIEWER";

  await writeAuditLogRecord({
    actorEmail: session.email.toLowerCase(),
    actorRole,
    action: input.action,
    targetType: input.targetType,
    targetId: input.targetId ?? null,
    metadata: input.metadata,
  });
}
