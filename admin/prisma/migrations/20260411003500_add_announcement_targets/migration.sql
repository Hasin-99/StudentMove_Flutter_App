ALTER TABLE "announcements"
ADD COLUMN IF NOT EXISTS "target_departments" JSONB NOT NULL DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS "target_routes" JSONB NOT NULL DEFAULT '[]'::jsonb;
