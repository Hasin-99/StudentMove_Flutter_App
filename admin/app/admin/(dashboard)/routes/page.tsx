import { requireRole } from "@/lib/permissions";
import { listRoutesForAdmin } from "@/lib/transit-store";
import { createRoute, deleteRoute } from "./actions";

export default async function RoutesPage() {
  await requireRole("transport_admin");
  const routes = await listRoutesForAdmin();

  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-semibold text-zinc-900 dark:text-zinc-50">
        Routes
      </h1>

      <section className="rounded-xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-900">
        <h2 className="mb-4 text-lg font-medium">New route</h2>
        <form action={createRoute} className="flex flex-wrap items-end gap-3">
          <div>
            <label htmlFor="name" className="mb-1 block text-xs font-medium">
              Name
            </label>
            <input
              id="name"
              name="name"
              required
              placeholder="Uttara - DSC"
              className="w-56 rounded-lg border border-zinc-300 px-3 py-2 text-sm dark:border-zinc-600 dark:bg-zinc-950"
            />
          </div>
          <div>
            <label htmlFor="code" className="mb-1 block text-xs font-medium">
              Code (optional)
            </label>
            <input
              id="code"
              name="code"
              placeholder="UTT-DSC"
              className="w-36 rounded-lg border border-zinc-300 px-3 py-2 text-sm dark:border-zinc-600 dark:bg-zinc-950"
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
        <h2 className="mb-3 text-lg font-medium">All routes</h2>
        <ul className="divide-y divide-zinc-200 rounded-xl border border-zinc-200 dark:divide-zinc-800 dark:border-zinc-800">
          {routes.length === 0 ? (
            <li className="px-4 py-6 text-sm text-zinc-500">No routes yet.</li>
          ) : (
            routes.map((r) => (
              <li
                key={r.id}
                className="flex flex-wrap items-center justify-between gap-3 px-4 py-3"
              >
                <div>
                  <span className="font-medium text-zinc-900 dark:text-zinc-100">
                    {r.name}
                  </span>
                  {r.code ? (
                    <span className="ml-2 text-sm text-zinc-500">({r.code})</span>
                  ) : null}
                  <span className="ml-2 text-xs text-zinc-400">
                    {r.scheduleCount} schedule(s)
                  </span>
                </div>
                <form action={deleteRoute}>
                  <input type="hidden" name="id" value={r.id} />
                  <button
                    type="submit"
                    className="text-sm text-red-600 hover:underline dark:text-red-400"
                  >
                    Delete
                  </button>
                </form>
              </li>
            ))
          )}
        </ul>
      </section>
    </div>
  );
}
