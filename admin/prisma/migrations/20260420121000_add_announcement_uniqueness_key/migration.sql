ALTER TABLE "announcements"
ADD COLUMN IF NOT EXISTS "announcement_key" TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS "announcements_announcement_key_key"
ON "announcements"("announcement_key")
WHERE "announcement_key" IS NOT NULL;
