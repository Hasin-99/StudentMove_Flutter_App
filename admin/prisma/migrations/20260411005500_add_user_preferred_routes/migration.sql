ALTER TABLE "users"
ADD COLUMN IF NOT EXISTS "preferred_routes" JSONB NOT NULL DEFAULT '[]'::jsonb;
