# Firestore Seed Scripts

Use this script to quickly load realistic starter data for:

- `routes`
- `schedules`
- `announcements`
- `liveBuses`

## Prerequisites

- Firebase CLI authenticated (`firebase login`)
- Firestore initialized for the project
- Node.js available

## Seed production/dev project

```bash
cd tools/firestore_seed
npm install
FIREBASE_PROJECT_ID=studentmove-dev npm run seed
```

## Seed local emulator

Start emulator in another terminal:

```bash
firebase emulators:start --only firestore
```

Then seed emulator:

```bash
cd tools/firestore_seed
npm install
USE_FIRESTORE_EMULATOR=true FIREBASE_PROJECT_ID=studentmove-dev npm run seed
```

You can edit seed payloads in `tools/firestore_seed/seed_data.json`.
