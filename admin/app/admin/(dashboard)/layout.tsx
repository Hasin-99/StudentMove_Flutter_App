import Link from "next/link";
import { redirect } from "next/navigation";
import { getSession } from "@/lib/session";
import { logoutAction } from "./actions";

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const session = await getSession();
  if (!session.isAdmin) redirect("/admin/login");
  const role = session.role ?? "super_admin";

  return (
    <div className="flex min-h-full flex-col">
      <header className="border-b border-teal-800 bg-teal-700">
        <div className="mx-auto flex max-w-5xl flex-wrap items-center justify-between gap-4 px-4 py-3">
          <nav className="flex flex-wrap items-center gap-4 text-sm font-medium text-teal-50">
            <Link href="/admin" className="text-white">
              Dashboard
            </Link>
            <Link href="/admin/routes" className="hover:text-white">
              Routes
            </Link>
            <Link href="/admin/buses" className="hover:text-white">
              Buses
            </Link>
            <Link href="/admin/schedules" className="hover:text-white">
              Schedules
            </Link>
            <Link href="/admin/announcements" className="hover:text-white">
              Announcements
            </Link>
            <Link href="/admin/chat" className="hover:text-white">
              Chat
            </Link>
            <Link href="/admin/security" className="hover:text-white">
              Security
            </Link>
            {role === "super_admin" ? (
              <>
                <Link href="/admin/users" className="hover:text-white">
                  Users
                </Link>
                <Link href="/admin/audit-logs" className="hover:text-white">
                  Audit Logs
                </Link>
              </>
            ) : null}
          </nav>
          <div className="inline-flex items-center gap-3">
            <span className="rounded bg-teal-900/50 px-2 py-1 text-xs uppercase tracking-wide text-teal-100">
              {role.replace("_", " ")}
            </span>
            <form action={logoutAction}>
              <button
                type="submit"
                className="text-sm text-teal-100 hover:text-white"
              >
                Log out
              </button>
            </form>
          </div>
        </div>
      </header>
      <main className="mx-auto w-full max-w-5xl flex-1 px-4 py-8">{children}</main>
    </div>
  );
}
