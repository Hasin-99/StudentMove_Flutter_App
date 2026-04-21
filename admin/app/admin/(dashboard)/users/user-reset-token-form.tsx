"use client";

import { useActionState } from "react";
import { setUserResetToken, type UserActionState } from "./actions";

export default function UserResetTokenForm({ id }: { id: string }) {
  const [state, formAction, pending] = useActionState<UserActionState | null, FormData>(
    setUserResetToken,
    null,
  );

  return (
    <form action={formAction} className="mt-2 flex flex-wrap items-center gap-2">
      <input type="hidden" name="id" value={id} />
      <input
        name="resetToken"
        required
        minLength={4}
        placeholder="Admin reset token (share with user)"
        className="w-full max-w-sm rounded border border-zinc-300 bg-transparent px-3 py-2 text-sm dark:border-zinc-700"
      />
      <input
        name="validMinutes"
        type="number"
        min={5}
        max={1440}
        defaultValue={30}
        className="w-28 rounded border border-zinc-300 bg-transparent px-3 py-2 text-sm dark:border-zinc-700"
      />
      <button
        type="submit"
        disabled={pending}
        className="rounded border border-indigo-300 bg-indigo-50 px-3 py-2 text-xs font-medium text-indigo-800 hover:bg-indigo-100 disabled:opacity-60"
      >
        {pending ? "Saving..." : "Save reset token"}
      </button>
      {state?.error ? <p className="w-full text-xs text-red-600">{state.error}</p> : null}
      {state?.success ? <p className="w-full text-xs text-emerald-700">{state.success}</p> : null}
    </form>
  );
}
