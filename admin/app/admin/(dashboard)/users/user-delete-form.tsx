"use client";

import { useActionState } from "react";
import { deleteUser, type UserActionState } from "./actions";

export default function UserDeleteForm({ id }: { id: string }) {
  const [state, formAction, pending] = useActionState<UserActionState | null, FormData>(
    deleteUser,
    null,
  );

  return (
    <form action={formAction} className="inline">
      <input type="hidden" name="id" value={id} />
      <button
        type="submit"
        disabled={pending}
        className="text-xs text-red-600 hover:underline disabled:opacity-60 dark:text-red-400"
      >
        {pending ? "Deleting..." : "Delete"}
      </button>
      {state?.error ? <p className="mt-1 text-[11px] text-red-600">{state.error}</p> : null}
      {state?.success ? <p className="mt-1 text-[11px] text-emerald-700">{state.success}</p> : null}
    </form>
  );
}
