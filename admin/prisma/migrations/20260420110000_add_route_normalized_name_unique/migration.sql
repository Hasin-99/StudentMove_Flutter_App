ALTER TABLE "routes"
ADD COLUMN IF NOT EXISTS "normalized_name" TEXT;

UPDATE "routes"
SET "normalized_name" = TRIM(BOTH '-' FROM REGEXP_REPLACE(LOWER("name"), '[^a-z0-9]+', '-', 'g'))
WHERE "normalized_name" IS NULL OR "normalized_name" = '';

-- Safety net so migration does not fail if duplicates still exist.
WITH ranked AS (
  SELECT id, normalized_name, ROW_NUMBER() OVER (PARTITION BY normalized_name ORDER BY created_at, id) AS rn
  FROM "routes"
)
UPDATE "routes" r
SET "normalized_name" = CONCAT(r.normalized_name, '--dup-', r.id)
FROM ranked
WHERE r.id = ranked.id AND ranked.rn > 1;

ALTER TABLE "routes"
ALTER COLUMN "normalized_name" SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS "routes_normalized_name_key" ON "routes"("normalized_name");
