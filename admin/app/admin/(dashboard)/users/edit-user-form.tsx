"use client";

import { useActionState } from "react";
import { updateUser, type UpdateUserState } from "./actions";

type UserRow = {
  id: string;
  fullName: string;
  email: string;
  phone: string | null;
  studentId: string | null;
  department: string | null;
  role: "SUPER_ADMIN" | "TRANSPORT_ADMIN" | "VIEWER";
};

export default function EditUserForm({ user }: { user: UserRow }) {
  const [state, formAction, pending] = useActionState<UpdateUserState | null, FormData>(
    updateUser,
    null,
  );

  return (
    <form action={formAction} className="grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
      <input type="hidden" name="id" value={user.id} />
      <input
        name="fullName"
        defaultValue={user.fullName}
        required
        className="rounded border border-zinc-300 bg-transparent px-3 py-2 text-sm dark:border-zinc-700"
      />
      <input
        name="email"
        defaultValue={user.email}
        type="email"
        required
        className="rounded border border-zinc-300 bg-transparent px-3 py-2 text-sm dark:border-zinc-700"
      />
      <input
        name="phone"
        defaultValue={user.phone ?? ""}
        placeholder="Phone"
        className="rounded border border-zinc-300 bg-transparent px-3 py-2 text-sm dark:border-zinc-700"
      />
      <input
        name="studentId"
        defaultValue={user.studentId ?? ""}
        placeholder="Student ID"
        className="rounded border border-zinc-300 bg-transparent px-3 py-2 text-sm dark:border-zinc-700"
      />
      <input
        name="department"
        defaultValue={user.department ?? ""}
        placeholder="Department"
        className="rounded border border-zinc-300 bg-transparent px-3 py-2 text-sm dark:border-zinc-700"
      />
      <select
        name="role"
        defaultValue={user.role}
        className="rounded border border-zinc-300 bg-transparent px-3 py-2 text-sm dark:border-zinc-700"
      >
        <option value="VIEWER">Viewer</option>
        <option value="TRANSPORT_ADMIN">Transport admin</option>
        <option value="SUPER_ADMIN">Super admin</option>
      </select>
      {state?.error ? (
        <div className="sm:col-span-2 lg:col-span-5 rounded border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700 dark:border-red-900/60 dark:bg-red-950/30 dark:text-red-300">
          {state.error}
        </div>
      ) : null}
      {state?.success ? (
        <div className="sm:col-span-2 lg:col-span-5 rounded border border-emerald-200 bg-emerald-50 px-3 py-2 text-xs text-emerald-700 dark:border-emerald-900/60 dark:bg-emerald-950/30 dark:text-emerald-300">
          {state.success}
        </div>
      ) : null}
      <div className="sm:col-span-2 lg:col-span-5">
        <button
          type="submit"
          disabled={pending}
          className="rounded bg-teal-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-teal-700 disabled:opacity-60"
        >
          {pending ? "Saving..." : "Save changes"}
        </button>
      </div>
    </form>
  );
}
