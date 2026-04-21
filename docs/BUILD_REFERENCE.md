# StudentMove — Build reference (Flutter + Firebase + Admin)

This document is the **single overview** of how the three parts of this repository work together and how you run them. Deeper detail lives in the linked files under `docs/`.

## What is in this repo?

| Part | Location | Role |
|------|----------|------|
| **Mobile / desktop app** | Repo root (`lib/`, `android/`, `ios/`, `macos/`, …) | **Flutter** client. Talks to **Firebase** (Auth, Firestore, FCM, Functions, App Check). |
| **Shared backend** | `firestore.rules`, `firestore.indexes.json`, `functions/`, `firebase.json` | **Firebase** project(s): data, security rules, server logic. |
| **Admin panel** | `admin/` | **Next.js** web app for operators. Uses **Firebase Admin SDK** + **Firestore** (and optionally **Prisma/Postgres** while migrating). |

All three must target the **same Firebase project** for a given environment (e.g. `studentmove-dev`), or you will see “data in app but not in admin” (or the opposite).

## Architecture (one sentence)

Students and drivers use the **Flutter** app; staff use the **Admin** app; both read/write the same **Firestore** (and Auth) in one Firebase project, guarded by **Firestore rules** and optional **Cloud Functions**.

## Prerequisites

- **Flutter** SDK (stable), **Dart**, **Node.js** (LTS) for admin and Firebase CLI tooling  
- **Firebase CLI**: `npm install -g firebase-tools`  
- **FlutterFire CLI** (for regenerating options): `dart pub global activate flutterfire_cli`  
- **Xcode** (macOS + iOS), **Android Studio** or SDK (Android) as needed  

## Firebase projects and flavors

- Typical setup: **dev** project (`studentmove-dev`) and **prod** project (your production ID).  
- Flutter chooses options via **`FIREBASE_FLAVOR`** (see `lib/core/firebase_environment.dart` and `lib/core/firebase_bootstrap.dart`):
  - `dev` → `lib/firebase_options_dev.dart`
  - `prod` → `lib/firebase_options_prod.dart`
- Regenerate options after changing Firebase apps or platforms:

```bash
flutterfire configure --project=YOUR_DEV_ID --platforms=android,ios,macos,web --out=lib/firebase_options_dev.dart
flutterfire configure --project=YOUR_PROD_ID --platforms=android,ios,macos,web --out=lib/firebase_options_prod.dart
```

Full checklist: **`docs/firebase_setup.md`**.

## Running the Flutter app

From the **repository root**:

```bash
flutter pub get
flutter run --dart-define=FIREBASE_FLAVOR=dev
```

Optional **local emulators** (Auth/Firestore/Functions):

```bash
firebase emulators:start
flutter run --dart-define=FIREBASE_FLAVOR=dev --dart-define=USE_FIREBASE_EMULATOR=true
```

**macOS:** after changing signing or entitlements, open `macos/Runner.xcworkspace` in Xcode once, set your **Team**, and run from Xcode if keychain or sandbox issues appear.

## Running the Admin panel

From **`admin/`**:

```bash
cd admin
cp .env.example .env
# Edit .env: FIREBASE_PROJECT_ID, FIREBASE_WEB_API_KEY, FIREBASE_SERVICE_ACCOUNT_JSON,
# ADMIN_AUTH_PROVIDER, ADMIN_DATA_PROVIDER, ADMIN_SESSION_SECRET, DATABASE_URL (if using Prisma)
npm install
npm run dev
```

Open **http://localhost:3000** (or the URL Next prints).

- **`ADMIN_DATA_PROVIDER=firebase`** and **`ADMIN_AUTH_PROVIDER=firebase`**: admin uses **only** Firestore + Firebase Auth (no Prisma fallback for those paths). Align all three Firebase env vars with the **same** project as the Flutter app for that environment.  
- **`hybrid`**: can fall back to Postgres if Firebase is misconfigured — useful during migration, confusing if projects disagree.

Admin superuser **custom claims** (e.g. `super_admin`): see **`docs/admin_claims.md`** and `tools/admin_claims/set_admin_claim.mjs`.

## Pointing the Flutter app at the Admin HTTP API (if you still use it)

If any feature still calls the Next **REST** API, set the app’s base URL to the admin site origin (no trailing slash), e.g. `http://localhost:3000`. Contract notes: **`docs/firebase_contract_mapping.md`**.

Most student-facing data in this codebase is intended to load from **Firestore** directly, not from Laravel or a separate mobile stack.

## Deploying Firebase (rules, indexes, functions)

From **repo root** (with `firebase use` set to the right project):

```bash
firebase deploy --only firestore:rules,firestore:indexes
cd functions && npm install && npm run build && cd ..
firebase deploy --only functions
```

- Rules file: **`firestore.rules`**  
- Indexes: **`firestore.indexes.json`** (do not add single-field-only composites; Firebase rejects them.)  
- Security and ops: **`docs/security_checklist.md`**

## Admin database (Prisma) — when you need it

If `ADMIN_DATA_PROVIDER` or `ADMIN_AUTH_PROVIDER` is **`hybrid`** or **`prisma`**, configure **`DATABASE_URL`** / **`DIRECT_URL`** in `admin/.env` and run migrations from `admin/`:

```bash
npm run db:migrate
```

Pure Firebase-only operators can ignore Prisma once fully cut over.

## Where to go next

| Topic | Document |
|--------|-----------|
| Firebase console + CLI setup | `docs/firebase_setup.md` |
| Admin custom claims | `docs/admin_claims.md` |
| Seeding Firestore | `docs/firestore_seed.md` |
| API ↔ Firestore mapping | `docs/firebase_contract_mapping.md` |
| Production cutover | `docs/release_cutover.md` |
| Repo entry + quick commands | `README.md` |
| Long-form local run (paths, emulators) | `HOW_TO_RUN.md` |

This file intentionally does **not** describe React Native, Expo, or Laravel as the primary stack; those are not part of this repository’s intended build.
