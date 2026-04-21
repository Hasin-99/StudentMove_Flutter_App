CREATE TABLE IF NOT EXISTS "announcements" (
  "id" TEXT NOT NULL,
  "title" TEXT NOT NULL,
  "body" TEXT NOT NULL,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "is_pinned" BOOLEAN NOT NULL DEFAULT false,
  "publish_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "expires_at" TIMESTAMP(3),
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "announcements_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "announcements_is_active_publish_at_idx"
  ON "announcements"("is_active", "publish_at");
CREATE INDEX IF NOT EXISTS "announcements_is_pinned_publish_at_idx"
  ON "announcements"("is_pinned", "publish_at");
