WITH ranked AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY route_id, bus_id, weekday, time_label, date_label, origin
      ORDER BY created_at ASC, id ASC
    ) AS rn
  FROM "schedules"
)
DELETE FROM "schedules" s
USING ranked r
WHERE s.id = r.id AND r.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS "schedules_unique_slot_key"
ON "schedules"("route_id", "bus_id", "weekday", "time_label", "date_label", "origin");
