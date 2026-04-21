import { getTransitCounts } from "@/lib/transit-store";
import { getUserCounts } from "@/lib/users-store";

export const dynamic = "force-dynamic";

export default async function AdminDashboardPage() {
  const [usersResult, transitResult] = await Promise.allSettled([
    getUserCounts(),
    getTransitCounts(),
  ]);
  const { totalUsers, activeUsers } =
    usersResult.status === "fulfilled"
      ? usersResult.value
      : { totalUsers: 0, activeUsers: 0 };
  const { routes, buses, schedules } =
    transitResult.status === "fulfilled"
      ? transitResult.value
      : { routes: 0, buses: 0, schedules: 0 };

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-semibold text-zinc-900">
        Dashboard
      </h1>
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
        <_StatCard label="Users" value={totalUsers} />
        <_StatCard label="Active users" value={activeUsers} />
        <_StatCard label="Routes" value={routes} />
        <_StatCard label="Buses" value={buses} />
        <_StatCard label="Schedules" value={schedules} />
      </div>
      <p className="max-w-xl text-sm leading-relaxed text-zinc-700">
        Public API for the Flutter app:{" "}
        <code className="rounded bg-zinc-100 px-1.5 py-0.5 text-xs">
          GET /api/v1/schedules
        </code>
        . Point{" "}
        <code className="rounded bg-zinc-100 px-1.5 py-0.5 text-xs">
          API_BASE_URL
        </code>{" "}
        in Flutter to this site&apos;s origin (no trailing slash), e.g.{" "}
        <code className="rounded bg-zinc-100 px-1.5 py-0.5 text-xs">
          https://your-app.vercel.app
        </code>
        .
      </p>
      <ul className="list-inside list-disc text-sm text-zinc-700">
        <li>Manage student profiles in Users.</li>
        <li>Add routes and buses first, then schedule rows.</li>
        <li>Weekday 0 = Saturday … 5 = Thursday (same as the mobile tabs).</li>
      </ul>
    </div>
  );
}

function _StatCard({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-xl border border-zinc-200 bg-white px-4 py-3 shadow-sm">
      <p className="text-xs uppercase tracking-wide text-zinc-500">{label}</p>
      <p className="mt-1 text-2xl font-semibold text-zinc-900">
        {value}
      </p>
    </div>
  );
}
