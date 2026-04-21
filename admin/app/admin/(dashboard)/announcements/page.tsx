import { requireRole } from "@/lib/permissions";
import {
  listActiveUserProfilesForAudience,
  listAdminAnnouncements,
} from "@/lib/announcements-store";
import AudiencePreviewCard from "./preview-card";
import CreateAnnouncementForm from "./create-announcement-form";
import EditAnnouncementForm from "./edit-announcement-form";
import {
  deleteAnnouncement,
  publishAnnouncementNow,
  toggleAnnouncementActive,
} from "./actions";

export default async function AnnouncementsPage() {
  await requireRole("transport_admin");
  const [rows, audienceData] = await Promise.all([
    listAdminAnnouncements(),
    listActiveUserProfilesForAudience(),
  ]);
  const totalActiveUsers = audienceData.totalActiveUsers;
  const activeUserProfiles = audienceData.profiles;

  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-semibold text-zinc-900">Announcements</h1>

      <section className="rounded-xl border border-zinc-200 bg-white p-6">
        <h2 className="mb-4 text-lg font-medium">New announcement</h2>
        <CreateAnnouncementForm />
      </section>
      <AudiencePreviewCard />

      <section>
        <h2 className="mb-3 text-lg font-medium">All announcements</h2>
        <div className="space-y-3">
          {rows.length === 0 ? (
            <div className="rounded-xl border border-zinc-200 bg-white px-4 py-6 text-sm text-zinc-500">
              No announcements yet.
            </div>
          ) : (
            rows.map((a) => (
              <div key={a.id} className="rounded-xl border border-zinc-200 bg-white p-4">
                {(() => {
                  const deptTargets = Array.isArray(a.targetDepartments)
                    ? a.targetDepartments.map((v) => String(v).trim()).filter(Boolean)
                    : [];
                  const routeTargets = Array.isArray(a.targetRoutes)
                    ? a.targetRoutes.map((v) => String(v).trim()).filter(Boolean)
                    : [];
                  const estimatedAudience = estimateAudience(
                    deptTargets,
                    routeTargets,
                    activeUserProfiles,
                    totalActiveUsers,
                  );
                  const status = getAnnouncementStatus(a);
                  return (
                    <>
                      <div className="mb-2 flex flex-wrap items-center gap-2">
                        <span
                          className={`rounded px-2 py-1 text-xs ${
                            a.isActive ? "bg-green-100 text-green-700" : "bg-zinc-200 text-zinc-700"
                          }`}
                        >
                          {a.isActive ? "Active" : "Inactive"}
                        </span>
                        <span className="rounded bg-sky-100 px-2 py-1 text-xs text-sky-700">{status}</span>
                        {a.isPinned ? (
                          <span className="rounded bg-amber-100 px-2 py-1 text-xs text-amber-800">Pinned</span>
                        ) : null}
                        <span className="text-xs text-zinc-500">
                          {new Date(a.publishAt).toLocaleString()}
                          {a.expiresAt ? ` → ends ${new Date(a.expiresAt).toLocaleString()}` : ""}
                        </span>
                      </div>
                      <h3 className="text-base font-semibold text-zinc-900">{a.title}</h3>
                      <p className="mt-1 whitespace-pre-wrap text-sm text-zinc-700">{a.body}</p>
                      <div className="mt-2 flex flex-wrap gap-2 text-xs">
                        {deptTargets.length > 0 ? (
                          <span className="rounded bg-blue-50 px-2 py-1 text-blue-700">
                            Dept: {deptTargets.join(", ")}
                          </span>
                        ) : (
                          <span className="rounded bg-zinc-100 px-2 py-1 text-zinc-600">Dept: All</span>
                        )}
                        {routeTargets.length > 0 ? (
                          <span className="rounded bg-purple-50 px-2 py-1 text-purple-700">
                            Route: {routeTargets.join(", ")}
                          </span>
                        ) : (
                          <span className="rounded bg-zinc-100 px-2 py-1 text-zinc-600">Route: All</span>
                        )}
                      </div>
                      <div className="mt-2 text-xs text-zinc-600">
                        Estimated audience: <span className="font-semibold">{estimatedAudience}</span>
                      </div>
                      <div className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-2 text-xs">
                        <form action={publishAnnouncementNow}>
                          <input type="hidden" name="id" value={a.id} />
                          <button type="submit" className="text-emerald-700 hover:underline">
                            Publish now
                          </button>
                        </form>
                        <form action={toggleAnnouncementActive}>
                          <input type="hidden" name="id" value={a.id} />
                          <button type="submit" className="text-blue-600 hover:underline">
                            {a.isActive ? "Deactivate" : "Activate"}
                          </button>
                        </form>
                        <form action={deleteAnnouncement}>
                          <input type="hidden" name="id" value={a.id} />
                          <button type="submit" className="text-red-600 hover:underline">
                            Delete
                          </button>
                        </form>
                      </div>
                      <EditAnnouncementForm
                        id={a.id}
                        title={a.title}
                        body={a.body}
                        publishAt={a.publishAt}
                        expiresAt={a.expiresAt}
                        deptTargets={deptTargets}
                        routeTargets={routeTargets}
                        isPinned={a.isPinned}
                        isActive={a.isActive}
                      />
                    </>
                  );
                })()}
              </div>
            ))
          )}
        </div>
      </section>
    </div>
  );
}

function estimateAudience(
  deptTargets: string[],
  routeTargets: string[],
  activeUserProfiles: Array<{ department: string; preferredRoutes: string[] }>,
  totalActiveUsers: number,
) {
  if (deptTargets.length === 0 && routeTargets.length === 0) return totalActiveUsers;
  const deptSet = new Set(deptTargets.map((d) => d.toLowerCase()));
  const routeSet = new Set(routeTargets.map((r) => r.toLowerCase()));
  let count = 0;
  for (const u of activeUserProfiles) {
    const deptOk = deptTargets.length === 0 || (u.department && deptSet.has(u.department));
    const routeOk =
      routeTargets.length === 0 || u.preferredRoutes.some((routeName) => routeSet.has(routeName));
    if (deptOk && routeOk) count++;
  }
  return count;
}

function getAnnouncementStatus(a: {
  isActive: boolean;
  publishAt: Date;
  expiresAt: Date | null;
}) {
  const now = Date.now();
  if (!a.isActive) return "Draft";
  if (a.publishAt.getTime() > now) return "Scheduled";
  if (a.expiresAt && a.expiresAt.getTime() <= now) return "Expired";
  return "Live";
}
