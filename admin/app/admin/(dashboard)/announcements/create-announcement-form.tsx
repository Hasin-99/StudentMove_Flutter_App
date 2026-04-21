"use client";

import { useActionState } from "react";
import { createAnnouncement, type CreateAnnouncementState } from "./actions";

export default function CreateAnnouncementForm() {
  const [state, formAction, pending] = useActionState<CreateAnnouncementState | null, FormData>(
    createAnnouncement,
    null,
  );

  return (
    <form action={formAction} className="grid gap-4 sm:grid-cols-2">
      <div className="sm:col-span-2">
        <label className="mb-1 block text-xs font-medium">Title</label>
        <input name="title" required className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm" />
      </div>
      <div className="sm:col-span-2">
        <label className="mb-1 block text-xs font-medium">Body</label>
        <textarea
          name="body"
          required
          rows={3}
          className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm"
        />
      </div>
      <div>
        <label className="mb-1 block text-xs font-medium">Publish at</label>
        <input
          name="publishAt"
          type="datetime-local"
          className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm"
        />
        <p className="mt-1 text-xs text-zinc-500">Leave empty to publish immediately.</p>
      </div>
      <div>
        <label className="mb-1 block text-xs font-medium">Expires at (optional)</label>
        <input
          name="expiresAt"
          type="datetime-local"
          className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm"
        />
      </div>
      <div>
        <label className="mb-1 block text-xs font-medium">Target departments (comma separated)</label>
        <input
          name="targetDepartments"
          placeholder="CSE, EEE"
          className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm"
        />
      </div>
      <div>
        <label className="mb-1 block text-xs font-medium">Target routes (comma separated)</label>
        <input
          name="targetRoutes"
          placeholder="Uttara - DSC, Uttara - DU"
          className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm"
        />
      </div>
      <label className="inline-flex items-center gap-2 text-sm">
        <input name="isPinned" type="checkbox" />
        Pinned
      </label>
      <label className="inline-flex items-center gap-2 text-sm">
        <input name="isActive" type="checkbox" defaultChecked />
        Active
      </label>
      {state?.error ? (
        <div className="sm:col-span-2 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
          {state.error}
        </div>
      ) : null}
      {state?.success ? (
        <div className="sm:col-span-2 rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-700">
          {state.success}
        </div>
      ) : null}
      <div className="sm:col-span-2">
        <button
          type="submit"
          disabled={pending}
          className="rounded-lg bg-teal-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-60"
        >
          {pending ? "Publishing..." : "Publish"}
        </button>
      </div>
    </form>
  );
}
