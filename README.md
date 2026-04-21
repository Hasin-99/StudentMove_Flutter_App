# StudentMove - Flutter + Firebase

Smart transportation app for Dhaka students, built with Flutter and a Firebase-first backend.

**Architecture and how to run everything together (Flutter app + Firebase + admin):** see [`docs/BUILD_REFERENCE.md`](docs/BUILD_REFERENCE.md).

## Backend Stack

- Firebase Authentication (email/password)
- Cloud Firestore (users, schedules, announcements, live buses, chat, preferences)
- Cloud Functions (privileged writes + audit events)
- Firebase Storage (chat attachment paths and admin assets)

## Quick Start

1) Install Flutter dependencies:

```bash
flutter pub get
```

2) Configure Firebase projects and FlutterFire files:

- Follow `docs/firebase_setup.md`
- Copy `.firebaserc.example` to `.firebaserc`
- Generate `lib/firebase_options_dev.dart` and `lib/firebase_options_prod.dart` with `flutterfire configure`

3) Run app:

```bash
flutter run --dart-define=FIREBASE_FLAVOR=dev
```

4) Optional local emulators:

```bash
firebase emulators:start
flutter run --dart-define=FIREBASE_FLAVOR=dev --dart-define=USE_FIREBASE_EMULATOR=true
```

## Security and Operations

- Firestore rules: `firestore.rules`
- Firestore indexes: `firestore.indexes.json`
- Storage rules: `storage.rules`
- Functions code: `functions/src/index.ts`
- Security checklist: `docs/security_checklist.md`
- REST-to-Firebase contract map: `docs/firebase_contract_mapping.md`
- Firestore seed workflow: `docs/firestore_seed.md`
- Env drift check: `./tools/check_firebase_env.sh`
- Admin claims helper: `docs/admin_claims.md`
