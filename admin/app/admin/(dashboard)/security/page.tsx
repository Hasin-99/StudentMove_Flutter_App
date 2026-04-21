import { requireRole } from "@/lib/permissions";
import AdminResetForm from "./admin-reset-form";
import PasswordForm from "./password-form";

export default async function SecurityPage() {
  const role = await requireRole("viewer");

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold text-zinc-900 dark:text-zinc-50">
        Security
      </h1>
      <section className="rounded-xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-900">
        <h2 className="mb-2 text-lg font-medium">Change password</h2>
        <p className="mb-4 text-sm text-zinc-600 dark:text-zinc-400">
          Use at least 8 characters and avoid reusing old passwords.
        </p>
        <PasswordForm />
      </section>
      {role === "super_admin" ? (
        <section className="rounded-xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-900">
          <h2 className="mb-2 text-lg font-medium">Super admin reset</h2>
          <p className="mb-4 text-sm text-zinc-600 dark:text-zinc-400">
            Reset another admin&apos;s password without email flow. Share the new password through a trusted channel.
          </p>
          <AdminResetForm />
        </section>
      ) : null}
    </div>
  );
}
