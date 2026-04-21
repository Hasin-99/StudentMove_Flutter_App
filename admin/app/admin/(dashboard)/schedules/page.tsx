import { requireRole } from "@/lib/permissions";
import {
  listBusesForAdmin,
  listRoutesForAdmin,
  listSchedulesForAdmin,
} from "@/lib/transit-store";
import { WEEKDAY_LABELS } from "@/lib/weekdays";
import { deleteSchedule } from "./actions";
import ScheduleForm from "./schedule-form";

export default async function SchedulesPage() {
  await requireRole("transport_admin");
  const [routes, buses, schedules] = await Promise.all([
    listRoutesForAdmin(),
    listBusesForAdmin(),
    listSchedulesForAdmin(),
  ]);

  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-semibold text-zinc-900 dark:text-zinc-50">
        Schedules
      </h1>

      <section className="rounded-xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-900">
        <h2 className="mb-4 text-lg font-medium">New row</h2>
        <ScheduleForm routes={routes} buses={buses} />
      </section>

      <section>
        <h2 className="mb-3 text-lg font-medium">All rows</h2>
        <div className="overflow-x-auto rounded-xl border border-zinc-200 dark:border-zinc-800">
          <table className="w-full min-w-[640px] text-left text-sm">
            <thead className="border-b border-zinc-200 bg-zinc-50 dark:border-zinc-800 dark:bg-zinc-900">
              <tr>
                <th className="px-3 py-2 font-medium">Route</th>
                <th className="px-3 py-2 font-medium">Day</th>
                <th className="px-3 py-2 font-medium">Time</th>
                <th className="px-3 py-2 font-medium">Bus</th>
                <th className="px-3 py-2 font-medium">Origin</th>
                <th className="px-3 py-2 font-medium">Whiteboard note</th>
                <th className="px-3 py-2 font-medium" />
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-200 dark:divide-zinc-800">
              {schedules.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-3 py-6 text-zinc-500">
                    No schedules yet.
                  </td>
                </tr>
              ) : (
                schedules.map((s) => (
                  <tr key={s.id}>
                    <td className="px-3 py-2">{s.routeName}</td>
                    <td className="px-3 py-2">
                      {WEEKDAY_LABELS[s.weekday] ?? s.weekday}
                    </td>
                    <td className="px-3 py-2">{s.timeLabel}</td>
                    <td className="px-3 py-2 font-mono">{s.busCode}</td>
                    <td className="px-3 py-2">{s.origin}</td>
                    <td className="px-3 py-2 text-xs text-zinc-600 dark:text-zinc-300">
                      {s.whiteboardNote || "-"}
                    </td>
                    <td className="px-3 py-2 text-right">
                      <form action={deleteSchedule} className="inline">
                        <input type="hidden" name="id" value={s.id} />
                        <button
                          type="submit"
                          className="text-red-600 hover:underline dark:text-red-400"
                        >
                          Delete
                        </button>
                      </form>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
