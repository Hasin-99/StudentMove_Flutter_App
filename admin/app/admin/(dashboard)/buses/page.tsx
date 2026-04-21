import { requireRole } from "@/lib/permissions";
import { listBusesForAdmin } from "@/lib/transit-store";
import { createBus, deleteBus } from "./actions";

export default async function BusesPage() {
  await requireRole("transport_admin");
  const buses = await listBusesForAdmin();

  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-semibold text-zinc-900 dark:text-zinc-50">
        Buses
      </h1>

      <section className="rounded-xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-900">
        <h2 className="mb-4 text-lg font-medium">New bus</h2>
        <form action={createBus} className="flex flex-wrap items-end gap-3">
          <div>
            <label htmlFor="code" className="mb-1 block text-xs font-medium">
              Bus code
            </label>
            <input
              id="code"
              name="code"
              required
              placeholder="SM-101"
              className="w-40 rounded-lg border border-zinc-300 px-3 py-2 text-sm dark:border-zinc-600 dark:bg-zinc-950"
            />
          </div>
          <button
            type="submit"
            className="rounded-lg bg-teal-600 px-4 py-2 text-sm font-medium text-white hover:bg-teal-700"
          >
            Add
          </button>
        </form>
      </section>

      <section>
        <h2 className="mb-3 text-lg font-medium">All buses</h2>
        <ul className="divide-y divide-zinc-200 rounded-xl border border-zinc-200 dark:divide-zinc-800 dark:border-zinc-800">
          {buses.length === 0 ? (
            <li className="px-4 py-6 text-sm text-zinc-500">No buses yet.</li>
          ) : (
            buses.map((b) => (
              <li
                key={b.id}
                className="flex flex-wrap items-center justify-between gap-3 px-4 py-3"
              >
                <div>
                  <span className="font-mono font-medium text-zinc-900 dark:text-zinc-100">
                    {b.code}
                  </span>
                  <span className="ml-2 text-xs text-zinc-400">
                    {b.scheduleCount} schedule(s)
                  </span>
                </div>
                {b.scheduleCount === 0 ? (
                  <form action={deleteBus}>
                    <input type="hidden" name="id" value={b.id} />
                    <button
                      type="submit"
                      className="text-sm text-red-600 hover:underline dark:text-red-400"
                    >
                      Delete
                    </button>
                  </form>
                ) : (
                  <span className="text-xs text-zinc-400">In use</span>
                )}
              </li>
            ))
          )}
        </ul>
      </section>
    </div>
  );
}
