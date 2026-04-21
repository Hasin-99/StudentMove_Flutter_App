# Firebase Setup (Dev + Prod)

This project uses two Firebase projects:

- `studentmove-dev` for local development and testing
- `studentmove-prod` for production release

## 1) Install toolchain

- Firebase CLI: `npm install -g firebase-tools`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

## 2) Authenticate and create projects

```bash
firebase login
firebase projects:create studentmove-dev
firebase projects:create studentmove-prod
```

Enable services in both projects:

- Authentication (Email/Password)
- Cloud Firestore
- Cloud Functions
- Cloud Storage
- Cloud Messaging
- App Check

## 3) Link local project

Copy `.firebaserc.example` to `.firebaserc` and set your project IDs.

```bash
cp .firebaserc.example .firebaserc
firebase use studentmove-dev
```

## 4) Configure Flutter apps

From repo root:

```bash
flutterfire configure --project=studentmove-dev --platforms=android,ios --out=lib/firebase_options_dev.dart
flutterfire configure --project=studentmove-prod --platforms=android,ios --out=lib/firebase_options_prod.dart
```

Ensure `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` exist for your selected environment.

## 5) Firestore and Functions bootstrap

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
cd functions && npm install && npm run build && cd ..
firebase deploy --only functions
```

## 6) Emulator workflow

```bash
firebase use studentmove-dev
firebase emulators:start
```

Optional Flutter run with emulators:

```bash
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

## 7) Rules tests

Run Firestore security tests against local emulator:

```bash
firebase emulators:start --only firestore
cd firebase_tests
npm install
npm run test:rules
```

## 8) Dev/Prod build targets

Native Firebase config now auto-switches by build target:

- Android:
  - `android/app/src/dev/google-services.json`
  - `android/app/src/prod/google-services.json`
- iOS:
  - `ios/Runner/Firebase/dev/GoogleService-Info.plist`
  - `ios/Runner/Firebase/prod/GoogleService-Info.plist`

Run commands:

```bash
# Dev
flutter run --flavor dev --dart-define=FIREBASE_FLAVOR=dev

# Prod
flutter run --flavor prod --dart-define=FIREBASE_FLAVOR=prod
```

On iOS, shared schemes now include:

- `dev` -> `Debug-dev`, `Profile-dev`, `Release-dev`
- `prod` -> `Debug-prod`, `Profile-prod`, `Release-prod`
