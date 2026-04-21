# Schedule Uniqueness Migration

This project now enforces uniqueness for schedule rows by:

- `routeId`
- `busId`
- `weekday`
- `timeLabel`
- `dateLabel`
- `origin`

## Why

Duplicate schedule rows create repeated entries in the mobile schedule view and operational confusion.

## Safe rollout steps

1. Stop schedule write traffic.
2. Dedupe existing data:

```bash
npm run schedules:dedupe
```

3. Apply DB migration:

```bash
npm run db:migrate
```

4. Restart the app.

## Notes

- App-layer duplicate prevention is also enabled in `createScheduleRecord()`.
- Firestore lock collection used for uniqueness in hybrid/firebase path: `scheduleUniqueLocks/{scheduleKey}`.
