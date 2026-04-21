import { requireRole } from "@/lib/permissions";
import { getAuditLogs, type AuditRow } from "@/lib/audit-store";

type AuditLogsPageProps = {
  searchParams?: Promise<{
    q?: string;
    action?: string;
    page?: string;
  }>;
};

export default async function AuditLogsPage({ searchParams }: AuditLogsPageProps) {
  await requireRole("super_admin");

  const params = (await searchParams) ?? {};
  const q = (params.q ?? "").trim();
  const action = (params.action ?? "").trim();
  const page = Math.max(Number(params.page ?? "1") || 1, 1);
  const perPage = 25;

  let rows: AuditRow[] = [];
  let totalPages = 1;
  let currentPage = 1;
  let actions: string[] = [];
  try {
    const result = await getAuditLogs({
      q,
      action,
      page,
      perPage,
    });
    rows = result.rows;
    totalPages = result.totalPages;
    currentPage = result.currentPage;
    actions = result.actions;
  } catch (error) {
    console.error("[admin/audit-logs] page load failed", error);
  }

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-semibold text-zinc-900">Audit Logs</h1>
      <div>
        <a
          href={buildExportUrl({ q, action })}
          className="inline-flex rounded border border-teal-300 bg-teal-50 px-3 py-2 text-xs font-medium text-teal-800 hover:bg-teal-100"
        >
          Export CSV
        </a>
      </div>
      <form method="get" className="grid gap-2 rounded-lg border border-zinc-200 bg-white p-3 sm:grid-cols-3">
        <input
          name="q"
          defaultValue={q}
          placeholder="Search actor / target"
          className="rounded border border-zinc-300 px-3 py-2 text-sm"
        />
        <select
          name="action"
          defaultValue={action}
          className="rounded border border-zinc-300 px-3 py-2 text-sm"
        >
          <option value="">All actions</option>
          {actions.map((a) => (
            <option key={a} value={a}>
              {a}
            </option>
          ))}
        </select>
        <button type="submit" className="rounded bg-teal-600 px-3 py-2 text-sm font-medium text-white">
          Filter
        </button>
      </form>

      <div className="overflow-x-auto rounded-lg border border-zinc-200 bg-white">
        <table className="min-w-full text-sm">
          <thead className="bg-zinc-50">
            <tr className="text-left text-xs uppercase text-zinc-500">
              <th className="px-3 py-2">Time</th>
              <th className="px-3 py-2">Actor</th>
              <th className="px-3 py-2">Action</th>
              <th className="px-3 py-2">Target</th>
              <th className="px-3 py-2">Details</th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 ? (
              <tr>
                <td className="px-3 py-6 text-zinc-500" colSpan={5}>
                  No audit records found.
                </td>
              </tr>
            ) : (
              rows.map((r: AuditRow) => (
                <tr key={r.id} className="border-t border-zinc-100 align-top">
                  <td className="px-3 py-2 text-xs text-zinc-600">
                    {new Date(r.createdAt).toLocaleString()}
                  </td>
                  <td className="px-3 py-2">
                    <div className="font-medium text-zinc-900">{r.actorEmail}</div>
                    <div className="text-xs uppercase text-zinc-500">{String(r.actorRole).replace("_", " ")}</div>
                  </td>
                  <td className="px-3 py-2 font-mono text-xs">{r.action}</td>
                  <td className="px-3 py-2 text-xs">
                    {r.targetType}
                    {r.targetId ? `:${r.targetId}` : ""}
                  </td>
                  <td className="px-3 py-2">
                    <pre className="max-w-xl overflow-auto whitespace-pre-wrap break-words text-xs text-zinc-700">
                      {r.metadata ? JSON.stringify(r.metadata) : "-"}
                    </pre>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div className="flex items-center justify-between text-xs">
        <a
          href={buildUrl({ q, action, page: Math.max(currentPage - 1, 1) })}
          aria-disabled={currentPage <= 1}
          className={currentPage <= 1 ? "pointer-events-none text-zinc-400" : "text-teal-700"}
        >
          Previous
        </a>
        <span>
          Page {currentPage} / {totalPages}
        </span>
        <a
          href={buildUrl({ q, action, page: Math.min(currentPage + 1, totalPages) })}
          aria-disabled={currentPage >= totalPages}
          className={currentPage >= totalPages ? "pointer-events-none text-zinc-400" : "text-teal-700"}
        >
          Next
        </a>
      </div>
    </div>
  );
}

function buildUrl({ q, action, page }: { q: string; action: string; page: number }) {
  const params = new URLSearchParams();
  if (q) params.set("q", q);
  if (action) params.set("action", action);
  if (page > 1) params.set("page", String(page));
  const qs = params.toString();
  return qs ? `/admin/audit-logs?${qs}` : "/admin/audit-logs";
}

function buildExportUrl({ q, action }: { q: string; action: string }) {
  const params = new URLSearchParams();
  if (q) params.set("q", q);
  if (action) params.set("action", action);
  const qs = params.toString();
  return qs ? `/admin/audit-logs/export?${qs}` : "/admin/audit-logs/export";
}
