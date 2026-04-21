# Announcement Uniqueness Migration

Announcements are now deduplicated by:

- normalized `title`
- normalized `body`
- normalized target departments
- normalized target routes
- `publishAt` rounded to the same minute

This allows the same announcement text at different publish times, and allows different route/department targeting.

## Safe rollout

1. Pause announcement write traffic.
2. Run:

```bash
npm run announcements:dedupe
```

3. Apply migration:

```bash
npm run db:migrate
```

4. Restart admin.

## Firestore lock

Firestore create path uses:

- `announcementUniqueLocks/{announcementKey}`

to prevent race-condition duplicates.
