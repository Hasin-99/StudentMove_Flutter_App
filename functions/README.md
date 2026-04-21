# Cloud Functions

Production-sensitive writes and workflows are centralized here.

## Functions

- `announce`: Admin-only announcement creation + audit event.
- `upsertLiveBus`: Admin-only live bus telemetry update + audit event.

## Local development

```bash
cd functions
npm install
npm run build
cd ..
firebase emulators:start
```

## Deployment

```bash
cd functions && npm install && npm run build && cd ..
firebase deploy --only functions
```
