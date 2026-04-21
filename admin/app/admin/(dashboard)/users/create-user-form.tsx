"use client";

import { useActionState } from "react";
import { createUser, type CreateUserState } from "./actions";

export default function CreateUserForm() {
  const [state, formAction, pending] = useActionState<CreateUserState | null, FormData>(
    createUser,
    null,
  );

  return (
    <form action={formAction} className="grid gap-4 sm:grid-cols-2">
      <div>
        <label className="mb-1 block text-xs font-medium">Full name</label>
        <input
          name="fullName"
          required
          placeholder="Monie Islam"
          className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm dark:border-zinc-600 dark:bg-zinc-950"
        />
      </div>
      <div>
        <label className="mb-1 block text-xs font-medium">Email</label>
        <input
          name="email"
          type="email"
          required
          placeholder="student@univ.edu"
          className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm dark:border-zinc-600 dark:bg-zinc-950"
        />
      </div>
      <div>
        <label className="mb-1 block text-xs font-medium">Phone</label>
        <input
          name="phone"
          placeholder="01XXXXXXXXX"
          className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm dark:border-zinc-600 dark:bg-zinc-950"
        />
      </div>
      <div>
        <label className="mb-1 block text-xs font-medium">Student ID</label>
        <input
          name="studentId"
          placeholder="221-15-XXXX"
          className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm dark:border-zinc-600 dark:bg-zinc-950"
        />
      </div>
      <div className="sm:col-span-2">
        <label className="mb-1 block text-xs font-medium">Department</label>
        <input
          name="department"
          placeholder="CSE"
          className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm dark:border-zinc-600 dark:bg-zinc-950"
        />
      </div>
      <div className="sm:col-span-2">
        <label className="mb-1 block text-xs font-medium">Role</label>
        <select
          name="role"
          defaultValue="VIEWER"
          className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm dark:border-zinc-600 dark:bg-zinc-950"
        >
          <option value="VIEWER">Viewer</option>
          <option value="TRANSPORT_ADMIN">Transport admin</option>
          <option value="SUPER_ADMIN">Super admin</option>
        </select>
      </div>
      <div className="sm:col-span-2">
        <label className="mb-1 block text-xs font-medium">Initial password (optional)</label>
        <input
          name="password"
          type="password"
          placeholder="Min 8 characters"
          className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm dark:border-zinc-600 dark:bg-zinc-950"
        />
      </div>
      {state?.error ? (
        <div className="sm:col-span-2 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700 dark:border-red-900/60 dark:bg-red-950/30 dark:text-red-300">
          {state.error}
        </div>
      ) : null}
      {state?.success ? (
        <div className="sm:col-span-2 rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-700 dark:border-emerald-900/60 dark:bg-emerald-950/30 dark:text-emerald-300">
          {state.success}
        </div>
      ) : null}
      <div className="sm:col-span-2">
        <button
          type="submit"
          disabled={pending}
          className="rounded-lg bg-teal-600 px-4 py-2 text-sm font-medium text-white hover:bg-teal-700 disabled:opacity-60"
        >
          {pending ? "Adding..." : "Add user"}
        </button>
      </div>
    </form>
  );
}
