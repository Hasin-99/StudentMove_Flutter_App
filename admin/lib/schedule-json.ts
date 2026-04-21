import type { Prisma } from "@prisma/client";

export type ScheduleRow = Prisma.ScheduleGetPayload<{
  include: { route: true; bus: true };
}>;

export function toFlutterScheduleSlot(row: ScheduleRow) {
  const raw = row.universityTags;
  const university_tags = Array.isArray(raw) ? raw.map((t) => String(t)) : [];

  return {
    route_name: row.route.name,
    day_index: row.weekday,
    time_label: row.timeLabel,
    date_label: row.dateLabel,
    origin: row.origin,
    bus_code: row.bus.code,
    whiteboard_note: row.whiteboardNote ?? "",
    university_tags,
  };
}
