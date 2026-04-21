# Route Uniqueness Migration

This project now enforces route uniqueness by normalized route name.

## Why

Duplicate route names cause ambiguous schedule mappings and announcement targeting.

## What changed

- App-layer duplicate prevention in `createRouteRecord()` for both Firebase and Prisma paths.
- Firestore uniqueness lock collection: `routeUniqueLocks/{normalizedName}`.
- Prisma schema now includes `routes.normalized_name` with unique constraint.

## Safe rollout steps

1. Stop dev/prod write traffic to route creation.
2. Run dedupe tool:

```bash
npm run routes:dedupe
```

3. Apply DB migration:

```bash
npm run db:migrate
```

4. Restart app services.

## Notes

- The migration SQL includes a safety net that suffixes colliding normalized names if any remain.
- Preferred path is to run `routes:dedupe` first so one canonical route remains per normalized name.
