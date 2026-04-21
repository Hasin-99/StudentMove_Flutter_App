import { redirect } from "next/navigation";
import { getSession } from "@/lib/session";
import LoginForm from "./login-form";

export default async function AdminLoginPage() {
  const session = await getSession();
  if (session.isAdmin) redirect("/admin");

  return (
    <div className="flex min-h-full flex-1 flex-col items-center justify-center bg-zinc-100 px-4 py-16 dark:bg-zinc-950">
      <div className="w-full max-w-md rounded-2xl border border-zinc-200 bg-white p-8 shadow-sm dark:border-zinc-800 dark:bg-zinc-900">
        <h1 className="mb-1 text-2xl font-semibold text-zinc-900 dark:text-zinc-50">
          StudentMove Admin
        </h1>
        <p className="mb-8 text-sm text-zinc-600 dark:text-zinc-400">
          Sign in with your admin email and password.
        </p>
        <LoginForm />
      </div>
    </div>
  );
}
