import { requireRole } from "@/lib/permissions";
import { listUsersForAdmin } from "@/lib/users-store";

export const dynamic = "force-dynamic";
import CreateUserForm from "./create-user-form";
import EditUserForm from "./edit-user-form";
import UserDeleteForm from "./user-delete-form";
import UserResetPasswordForm from "./user-reset-password-form";
import UserResetTokenForm from "./user-reset-token-form";
import UserToggleActiveForm from "./user-toggle-active-form";

type UsersPageProps = {
  searchParams?: Promise<{
    q?: string;
    status?: "all" | "active" | "inactive";
    department?: string;
    page?: string;
    perPage?: string;
  }>;
};

export default async function UsersPage({ searchParams }: UsersPageProps) {
  await requireRole("super_admin");
  const params = (await searchParams) ?? {};
  const q = (params.q ?? "").trim();
  const status = params.status ?? "all";
  const department = (params.department ?? "").trim();
  const page = Math.max(Number(params.page ?? "1") || 1, 1);
  const perPageOptions = [8, 20, 50];
  const parsedPerPage = Number(params.perPage ?? "8");
  const perPage = perPageOptions.includes(parsedPerPage) ? parsedPerPage : 8;

  const { items: users, totalUsers, totalPages, currentPage, departments } =
    await listUsersForAdmin({
      q,
      status,
      department,
      page,
      perPage,
    });

  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-semibold text-zinc-900 dark:text-zinc-50">
        Users
      </h1>

      <section className="rounded-xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-900">
        <h2 className="mb-4 text-lg font-medium">New user</h2>
        <CreateUserForm />
      </section>

      <section>
        <h2 className="mb-3 text-lg font-medium">Search & filters</h2>
        <form
          method="get"
          className="grid gap-3 rounded-xl border border-zinc-200 bg-white p-4 sm:grid-cols-2 lg:grid-cols-4 dark:border-zinc-800 dark:bg-zinc-900"
        >
          <input
            name="q"
            defaultValue={q}
            placeholder="Search name/email/phone/student ID"
            className="rounded border border-zinc-300 bg-transparent px-3 py-2 text-sm dark:border-zinc-700"
          />
          <select
            name="status"
            defaultValue={status}
            className="rounded border border-zinc-300 bg-transparent px-3 py-2 text-sm dark:border-zinc-700"
          >
            <option value="all">All status</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>
          <select
            name="department"
            defaultValue={department}
            className="rounded border border-zinc-300 bg-transparent px-3 py-2 text-sm dark:border-zinc-700"
          >
            <option value="">All departments</option>
            {departments.map((d) => (
              <option key={d} value={d}>
                {d}
              </option>
            ))}
          </select>
          <select
            name="perPage"
            defaultValue={String(perPage)}
            className="rounded border border-zinc-300 bg-transparent px-3 py-2 text-sm dark:border-zinc-700"
          >
            {perPageOptions.map((n) => (
              <option key={n} value={n}>
                {n} / page
              </option>
            ))}
          </select>
          <div className="inline-flex items-center gap-2">
            <button
              type="submit"
              className="rounded bg-teal-600 px-3 py-2 text-xs font-medium text-white hover:bg-teal-700"
            >
              Apply
            </button>
            <a
              href="/admin/users"
              className="rounded border border-zinc-300 px-3 py-2 text-xs font-medium hover:bg-zinc-50 dark:border-zinc-700 dark:hover:bg-zinc-800"
            >
              Reset
            </a>
          </div>
        </form>
      </section>

      <section>
        <h2 className="mb-3 text-lg font-medium">All users</h2>
        <p className="mb-3 text-xs text-zinc-500">
          Showing {(currentPage - 1) * perPage + (users.length == 0 ? 0 : 1)}-
          {(currentPage - 1) * perPage + users.length} of {totalUsers} users
        </p>
        <div className="space-y-3">
          {users.length === 0 ? (
            <div className="rounded-xl border border-zinc-200 px-4 py-6 text-sm text-zinc-500 dark:border-zinc-800">
              No users yet.
            </div>
          ) : (
            users.map((u) => (
              <div
                key={u.id}
                className="rounded-xl border border-zinc-200 bg-white p-4 dark:border-zinc-800 dark:bg-zinc-900"
              >
                <div className="mb-3 flex items-center justify-between">
                  <span
                    className={`rounded px-2 py-1 text-xs font-medium ${
                      u.isActive
                        ? "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300"
                        : "bg-zinc-200 text-zinc-700 dark:bg-zinc-800 dark:text-zinc-300"
                    }`}
                  >
                    {u.isActive ? "Active" : "Inactive"}
                  </span>
                  <div className="inline-flex gap-3">
                    <UserToggleActiveForm id={u.id} isActive={u.isActive} />
                    <UserDeleteForm id={u.id} />
                  </div>
                </div>
                <EditUserForm user={u} />
                <UserResetPasswordForm id={u.id} />
                <UserResetTokenForm id={u.id} />
              </div>
            ))
          )}
        </div>
        <div className="mt-4 flex items-center justify-between">
          <a
            href={buildUsersUrl({
              q,
              status,
              department,
              perPage,
              page: Math.max(currentPage - 1, 1),
            })}
            aria-disabled={currentPage <= 1}
            className={`rounded border px-3 py-2 text-xs font-medium ${
              currentPage <= 1
                ? "pointer-events-none border-zinc-200 text-zinc-400"
                : "border-teal-300 text-teal-700 hover:bg-teal-50"
            }`}
          >
            Previous
          </a>
          <span className="text-xs text-zinc-600">
            Page {currentPage} / {totalPages}
          </span>
          <div className="hidden items-center gap-1 sm:inline-flex">
            {buildPageItems(currentPage, totalPages).map((p) => (
              <a
                key={p}
                href={buildUsersUrl({
                  q,
                  status,
                  department,
                  perPage,
                  page: p,
                })}
                className={`rounded border px-2 py-1 text-xs ${
                  p === currentPage
                    ? "border-teal-600 bg-teal-600 text-white"
                    : "border-teal-300 text-teal-700 hover:bg-teal-50"
                }`}
              >
                {p}
              </a>
            ))}
          </div>
          <a
            href={buildUsersUrl({
              q,
              status,
              department,
              perPage,
              page: Math.min(currentPage + 1, totalPages),
            })}
            aria-disabled={currentPage >= totalPages}
            className={`rounded border px-3 py-2 text-xs font-medium ${
              currentPage >= totalPages
                ? "pointer-events-none border-zinc-200 text-zinc-400"
                : "border-teal-300 text-teal-700 hover:bg-teal-50"
            }`}
          >
            Next
          </a>
        </div>
      </section>
    </div>
  );
}

function buildUsersUrl({
  q,
  status,
  department,
  perPage,
  page,
}: {
  q: string;
  status: "all" | "active" | "inactive";
  department: string;
  perPage: number;
  page: number;
}) {
  const params = new URLSearchParams();
  if (q) params.set("q", q);
  if (status && status !== "all") params.set("status", status);
  if (department) params.set("department", department);
  if (perPage !== 8) params.set("perPage", String(perPage));
  if (page > 1) params.set("page", String(page));
  const qs = params.toString();
  return qs ? `/admin/users?${qs}` : "/admin/users";
}

function buildPageItems(currentPage: number, totalPages: number) {
  const start = Math.max(1, currentPage - 2);
  const end = Math.min(totalPages, currentPage + 2);
  const pages: number[] = [];
  for (let i = start; i <= end; i++) pages.push(i);
  return pages;
}
