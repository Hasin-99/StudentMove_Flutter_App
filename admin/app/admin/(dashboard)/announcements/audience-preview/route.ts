import { requireRole } from "@/lib/permissions";
import { listActiveUserProfilesForAudience } from "@/lib/announcements-store";

function parseCsv(raw: string): string[] {
  return raw
    .split(",")
    .map((v) => v.trim().toLowerCase())
    .filter(Boolean);
}

export async function GET(request: Request) {
  await requireRole("transport_admin");

  const url = new URL(request.url);
  const deptTargets = parseCsv(url.searchParams.get("departments") ?? "");
  const routeTargets = parseCsv(url.searchParams.get("routes") ?? "");

  const { totalActiveUsers, profiles } = await listActiveUserProfilesForAudience();
  const deptSet = new Set(deptTargets);
  const routeSet = new Set(routeTargets);
  let count = 0;

  for (const u of profiles) {
    const dept = (u.department ?? "").trim().toLowerCase();
    const userRoutes = u.preferredRoutes;

    const deptOk = deptTargets.length === 0 || (dept && deptSet.has(dept));
    const routeOk =
      routeTargets.length === 0 || userRoutes.some((routeName) => routeSet.has(routeName));

    if (deptOk && routeOk) count++;
  }

  return Response.json({
    count,
    totalActiveUsers,
    note:
      routeTargets.length > 0
        ? "Route-based estimate uses users' synced preferred routes."
        : undefined,
  });
}
