"use client";

import { useActionState } from "react";
import { toggleUserActive, type UserActionState } from "./actions";

export default function UserToggleActiveForm({
  id,
  isActive,
}: {
  id: string;
  isActive: boolean;
}) {
  const [state, formAction, pending] = useActionState<UserActionState | null, FormData>(
    toggleUserActive,
    null,
  );

  return (
    <form action={formAction} className="inline">
      <input type="hidden" name="id" value={id} />
      <button
        type="submit"
        disabled={pending}
        className="text-xs text-blue-600 hover:underline disabled:opacity-60 dark:text-blue-400"
      >
        {pending ? "Saving..." : isActive ? "Deactivate" : "Activate"}
      </button>
      {state?.error ? <p className="mt-1 text-[11px] text-red-600">{state.error}</p> : null}
      {state?.success ? <p className="mt-1 text-[11px] text-emerald-700">{state.success}</p> : null}
    </form>
  );
}
