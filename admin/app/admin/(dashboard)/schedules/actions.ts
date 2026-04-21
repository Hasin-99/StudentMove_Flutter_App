"use server";

import { revalidatePath } from "next/cache";
import { writeAuditLog } from "@/lib/audit-log";
import { requireRole } from "@/lib/permissions";
import { createScheduleRecord, deleteScheduleById, getScheduleById } from "@/lib/transit-store";

export type CreateScheduleState = {
  error?: string;
  success?: string;
};

async function guard() {
  await requireRole("transport_admin");
}

function parseTags(raw: string): string[] {
  return raw
    .split(/[,,]/)
    .map((t) => t.trim())
    .filter(Boolean);
}

function toTimeLabel(formData: FormData): string {
  const raw = String(formData.get("timeLabel") || "").trim();
  if (raw) return raw;
  const hour = Number(formData.get("timeHour"));
  const minute = Number(formData.get("timeMinute"));
  const meridiem = String(formData.get("timeMeridiem") || "").toUpperCase();
  if (!Number.isInteger(hour) || hour < 1 || hour > 12) return "";
  if (!Number.isInteger(minute) || minute < 0 || minute > 59) return "";
  if (meridiem !== "AM" && meridiem !== "PM") return "";
  const minuteText = String(minute).padStart(2, "0");
  return `${hour}:${minuteText} ${meridiem}`;
}

export async function createSchedule(
  _prevState: CreateScheduleState | null,
  formData: FormData,
): Promise<CreateScheduleState | null> {
  try {
    await guard();
    const routeId = String(formData.get("routeId") || "");
    const busId = String(formData.get("busId") || "");
    const weekday = Number(formData.get("weekday"));
    const timeLabel = toTimeLabel(formData);
    const dateLabel = String(formData.get("dateLabel") || "").trim();
    const origin = String(formData.get("origin") || "").trim();
    const whiteboardNote = String(formData.get("whiteboardNote") || "").trim();
    const tags = parseTags(String(formData.get("universityTags") || ""));

    if (!routeId || !busId || !timeLabel || !dateLabel || !origin) {
      return { error: "All required schedule fields must be provided." };
    }
    if (!Number.isInteger(weekday) || weekday < 0 || weekday > 5) {
      return { error: "Weekday must be between 0 and 5." };
    }

    const schedule = await createScheduleRecord({
      routeId,
      busId,
      weekday,
      timeLabel,
      dateLabel,
      origin,
      whiteboardNote: whiteboardNote || null,
      universityTags: tags,
    });
    await writeAuditLog({
      action: "schedule.create",
      targetType: "schedule",
      targetId: schedule.id,
      metadata: {
        routeId,
        busId,
        weekday,
        timeLabel,
        dateLabel,
        origin,
        whiteboardNote: whiteboardNote || null,
        universityTags: tags,
      },
    });
    revalidatePath("/admin/schedules");
    return { success: "Schedule created successfully." };
  } catch (error) {
    if (error instanceof Error && error.message === "duplicate_schedule") {
      console.error("[schedules] duplicate schedule blocked");
      return {
        error: "Duplicate schedule exists for this route, bus, day, time, date, and origin.",
      };
    }
    console.error("[schedules] createSchedule failed", error);
    return { error: "Could not create schedule. Please try again." };
  }
}

export async function deleteSchedule(formData: FormData) {
  try {
    await guard();
    const id = String(formData.get("id") || "");
    if (!id) return;
    const existing = await getScheduleById(id);
    await deleteScheduleById(id);
    await writeAuditLog({
      action: "schedule.delete",
      targetType: "schedule",
      targetId: id,
      metadata: existing
        ? {
            routeId: existing.routeId,
            busId: existing.busId,
            weekday: existing.weekday,
            timeLabel: existing.timeLabel,
          }
        : undefined,
    });
    revalidatePath("/admin/schedules");
  } catch (error) {
    console.error("[schedules] deleteSchedule failed", error);
  }
}
