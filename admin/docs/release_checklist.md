# Admin Release Checklist

Use this quick checklist before deploying the admin app.

## 1) Code and schema sync

- Pull latest code and install dependencies:
  - `npm install`
- Ensure Prisma schema is applied:
  - `npm run db:migrate`
- Regenerate Prisma client:
  - `npx prisma generate`

## 2) Data hygiene scripts (run when needed)

- Route dedupe: `npm run routes:dedupe`
- Schedule dedupe: `npm run schedules:dedupe`
- Announcement dedupe: `npm run announcements:dedupe`

## 3) Build and smoke checks

- Lint:
  - `npm run lint`
- Build:
  - `npm run build`
- Start app and test critical admin actions:
  - users create/update/toggle/delete/reset password/reset token
  - routes/buses/schedules create + duplicate protection
  - announcements create/update + duplicate protection

## 4) API response contract checks

For each `app/api/v1/*` route:

- Success responses return JSON via `jsonWithCors`.
- Error responses return:
  - `error.code`
  - `error.message`
  - `error.requestId`
- `X-Request-Id` header is present on:
  - success responses
  - error responses
  - `OPTIONS` preflight responses

Quick verification example:

```bash
curl -i "http://localhost:3000/api/v1/schedules"
```

Confirm response includes `X-Request-Id`.

## 5) Environment sanity

- `ADMIN_DATA_PROVIDER` is set correctly (`hybrid`, `firebase`, or `prisma`).
- Firebase env vars are valid when using Firebase paths:
  - `FIREBASE_PROJECT_ID`
  - `FIREBASE_SERVICE_ACCOUNT_JSON`
- Database URLs are valid for migrations/runtime:
  - `DATABASE_URL`
  - `DIRECT_URL`

## 6) Rollback prep

- Keep previous deploy artifact available.
- Keep last known good migration state documented.
- If a release fails, roll back app first, then assess data migrations.
