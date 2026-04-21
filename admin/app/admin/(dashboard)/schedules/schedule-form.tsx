"use client";

import { useActionState } from "react";
import { WEEKDAY_LABELS } from "@/lib/weekdays";
import { createSchedule, type CreateScheduleState } from "./actions";

type RouteOption = {
  id: string;
  name: string;
};

type BusOption = {
  id: string;
  code: string;
};

export default function ScheduleForm({
  routes,
  buses,
}: {
  routes: RouteOption[];
  buses: BusOption[];
}) {
  const [state, formAction, pending] = useActionState<CreateScheduleState | null, FormData>(
    createSchedule,
    null,
  );

  return (
    <form action={formAction} className="grid gap-4 sm:grid-cols-2">
      <div className="sm:col-span-2">
        <label className="mb-1 block text-xs font-medium">Route</label>
        <select
          name="routeId"
          required
          className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm dark:border-zinc-600 dark:bg-zinc-950"
        >
          <option value="">Select...</option>
          {routes.map((r) => (
            <option key={r.id} value={r.id}>
              {r.name}
            </option>
          ))}
        </select>
      </div>
      <div className="sm:col-span-2">
        <label className="mb-1 block text-xs font-medium">Bus</label>
        <select
          name="busId"
          required
          className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm dark:border-zinc-600 dark:bg-zinc-950"
        >
          <option value="">Select...</option>
          {buses.map((b) => (
            <option key={b.id} value={b.id}>
              {b.code}
            </option>
          ))}
        </select>
      </div>
      <div>
        <label className="mb-1 block text-xs font-medium">Weekday</label>
        <select
          name="weekday"
          required
          className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm dark:border-zinc-600 dark:bg-zinc-950"
        >
          {WEEKDAY_LABELS.map((label, i) => (
            <option key={label} value={i}>
              {label} ({i})
            </option>
          ))}
        </select>
      </div>
      <div>
        <label className="mb-1 block text-xs font-medium">Time (12-hour)</label>
        <div className="grid grid-cols-3 gap-2">
          <select
            name="timeHour"
            required
            defaultValue="7"
            className="rounded-lg border border-zinc-300 px-3 py-2 text-sm dark:border-zinc-600 dark:bg-zinc-950"
          >
            {Array.from({ length: 12 }).map((_, index) => {
              const hour = index + 1;
              return (
                <option key={hour} value={hour}>
                  {hour}
                </option>
              );
            })}
          </select>
          <select
            name="timeMinute"
            required
            defaultValue="0"
            className="rounded-lg border border-zinc-300 px-3 py-2 text-sm dark:border-zinc-600 dark:bg-zinc-950"
          >
            {Array.from({ length: 60 }).map((_, minute) => (
              <option key={minute} value={minute}>
                {String(minute).padStart(2, "0")}
              </option>
            ))}
          </select>
          <select
            name="timeMeridiem"
            required
            defaultValue="AM"
            className="rounded-lg border border-zinc-300 px-3 py-2 text-sm dark:border-zinc-600 dark:bg-zinc-950"
          >
            <option value="AM">AM</option>
            <option value="PM">PM</option>
          </select>
        </div>
      </div>
      <div>
        <label className="mb-1 block text-xs font-medium">Date label</label>
        <input
          name="dateLabel"
          required
          placeholder="12 May"
          className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm dark:border-zinc-600 dark:bg-zinc-950"
        />
      </div>
      <div>
        <label className="mb-1 block text-xs font-medium">Origin</label>
        <input
          name="origin"
          required
          placeholder="Rajhlokkhi"
          className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm dark:border-zinc-600 dark:bg-zinc-950"
        />
      </div>
      <div className="sm:col-span-2">
        <label className="mb-1 block text-xs font-medium">Whiteboard note (optional)</label>
        <textarea
          name="whiteboardNote"
          rows={2}
          placeholder="12 PM: Monie(7), Surjomokhi(1)"
          className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm dark:border-zinc-600 dark:bg-zinc-950"
        />
      </div>
      <div className="sm:col-span-2">
        <label className="mb-1 block text-xs font-medium">University tags (comma-separated)</label>
        <input
          name="universityTags"
          placeholder="DSC, Dhaka, Uttara"
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
          className="rounded-lg bg-teal-600 px-4 py-2 text-sm font-medium text-white hover:bg-teal-700 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {pending ? "Adding..." : "Add schedule"}
        </button>
      </div>
    </form>
  );
}
