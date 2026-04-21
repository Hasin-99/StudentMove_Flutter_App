"use client";

import { useActionState } from "react";
import { updateAnnouncement, type UpdateAnnouncementState } from "./actions";

type Props = {
  id: string;
  title: string;
  body: string;
  publishAt: Date;
  expiresAt: Date | null;
  deptTargets: string[];
  routeTargets: string[];
  isPinned: boolean;
  isActive: boolean;
};

function toDateTimeLocal(date: Date) {
  const d = new Date(date);
  const pad = (n: number) => n.toString().padStart(2, "0");
  const y = d.getFullYear();
  const m = pad(d.getMonth() + 1);
  const day = pad(d.getDate());
  const h = pad(d.getHours());
  const min = pad(d.getMinutes());
  return `${y}-${m}-${day}T${h}:${min}`;
}

export default function EditAnnouncementForm(props: Props) {
  const [state, formAction, pending] = useActionState<UpdateAnnouncementState | null, FormData>(
    updateAnnouncement,
    null,
  );

  return (
    <form action={formAction} className="mt-4 grid gap-2 rounded border border-zinc-200 p-3 sm:grid-cols-2">
      <input type="hidden" name="id" value={props.id} />
      <div className="sm:col-span-2">
        <label className="mb-1 block text-xs font-medium">Edit title</label>
        <input
          name="title"
          defaultValue={props.title}
          required
          className="w-full rounded border border-zinc-300 px-3 py-2 text-sm"
        />
      </div>
      <div className="sm:col-span-2">
        <label className="mb-1 block text-xs font-medium">Edit body</label>
        <textarea
          name="body"
          defaultValue={props.body}
          rows={2}
          required
          className="w-full rounded border border-zinc-300 px-3 py-2 text-sm"
        />
      </div>
      <div>
        <label className="mb-1 block text-xs font-medium">Publish at</label>
        <input
          name="publishAt"
          type="datetime-local"
          defaultValue={toDateTimeLocal(props.publishAt)}
          className="w-full rounded border border-zinc-300 px-3 py-2 text-sm"
        />
      </div>
      <div>
        <label className="mb-1 block text-xs font-medium">Expires at</label>
        <input
          name="expiresAt"
          type="datetime-local"
          defaultValue={props.expiresAt ? toDateTimeLocal(props.expiresAt) : ""}
          className="w-full rounded border border-zinc-300 px-3 py-2 text-sm"
        />
      </div>
      <div>
        <label className="mb-1 block text-xs font-medium">Target departments</label>
        <input
          name="targetDepartments"
          defaultValue={props.deptTargets.join(", ")}
          className="w-full rounded border border-zinc-300 px-3 py-2 text-sm"
        />
      </div>
      <div>
        <label className="mb-1 block text-xs font-medium">Target routes</label>
        <input
          name="targetRoutes"
          defaultValue={props.routeTargets.join(", ")}
          className="w-full rounded border border-zinc-300 px-3 py-2 text-sm"
        />
      </div>
      <label className="inline-flex items-center gap-2 text-xs">
        <input name="isPinned" type="checkbox" defaultChecked={props.isPinned} />
        Pinned
      </label>
      <label className="inline-flex items-center gap-2 text-xs">
        <input name="isActive" type="checkbox" defaultChecked={props.isActive} />
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
          className="rounded bg-zinc-900 px-3 py-2 text-xs font-medium text-white disabled:opacity-60"
        >
          {pending ? "Saving..." : "Save edits"}
        </button>
      </div>
    </form>
  );
}
