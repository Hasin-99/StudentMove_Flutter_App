"use client";

import { useActionState } from "react";
import { resetUserPassword, type UserActionState } from "./actions";

export default function UserResetPasswordForm({ id }: { id: string }) {
  const [state, formAction, pending] = useActionState<UserActionState | null, FormData>(
    resetUserPassword,
    null,
  );

  return (
    <form action={formAction} className="mt-3 flex flex-wrap items-center gap-2">
      <input type="hidden" name="id" value={id} />
      <input
        name="newPassword"
        type="password"
        minLength={8}
        required
        placeholder="Set/reset mobile password (min 8)"
        className="w-full max-w-sm rounded border border-zinc-300 bg-transparent px-3 py-2 text-sm dark:border-zinc-700"
      />
      <button
        type="submit"
        disabled={pending}
        className="rounded border border-amber-300 bg-amber-50 px-3 py-2 text-xs font-medium text-amber-800 hover:bg-amber-100 disabled:opacity-60"
      >
        {pending ? "Saving..." : "Set password"}
      </button>
      {state?.error ? <p className="w-full text-xs text-red-600">{state.error}</p> : null}
      {state?.success ? <p className="w-full text-xs text-emerald-700">{state.success}</p> : null}
    </form>
  );
}
