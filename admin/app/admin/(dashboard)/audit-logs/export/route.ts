import { requireRole } from "@/lib/permissions";
import { getAuditLogsForExport } from "@/lib/audit-store";

function esc(value: unknown) {
  const s = String(value ?? "");
  if (s.includes(",") || s.includes('"') || s.includes("\n")) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

export async function GET(request: Request) {
  await requireRole("super_admin");
  const url = new URL(request.url);
  const q = (url.searchParams.get("q") ?? "").trim();
  const action = (url.searchParams.get("action") ?? "").trim();

  const rows = await getAuditLogsForExport({ q, action });

  const header = [
    "created_at",
    "actor_email",
    "actor_role",
    "action",
    "target_type",
    "target_id",
    "metadata_json",
  ].join(",");
  const lines = rows.map((r) =>
    [
      esc(r.createdAt.toISOString()),
      esc(r.actorEmail),
      esc(r.actorRole),
      esc(r.action),
      esc(r.targetType),
      esc(r.targetId ?? ""),
      esc(r.metadata ? JSON.stringify(r.metadata) : ""),
    ].join(","),
  );

  const csv = [header, ...lines].join("\n");
  return new Response(csv, {
    status: 200,
    headers: {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": 'attachment; filename="audit-logs.csv"',
      "Cache-Control": "no-store",
    },
  });
}
