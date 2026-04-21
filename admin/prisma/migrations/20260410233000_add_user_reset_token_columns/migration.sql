ALTER TABLE "users"
ADD COLUMN IF NOT EXISTS "reset_token_hash" TEXT,
ADD COLUMN IF NOT EXISTS "reset_token_expires_at" TIMESTAMP(3);
