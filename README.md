# StudentMove — Flutter App

**Smart transport for Dhaka students** — live buses, routes, seat booking, student passes, chat, and driver GPS.

This repository is a **Flutter + Firebase** mobile app (Android / iOS / desktop / web targets).  
It is **not** a Laravel project.

> Related web/PWA (separate repo): [StudentMove-Smart-Transport-Solution-for-Dhaka](https://github.com/Tahis-Fzs/StudentMove-Smart-Transport-Solution-for-Dhaka)

---

## Features

- Live bus map with GPS freshness (live / stale / offline)
- Next-bus schedules (day tabs, filters, PDF export)
- Route planner + saved favorites
- Seat booking with confirmation codes and cancel
- Student passes: Weekly · Monthly · Single Ride
- AI assistant + support chat
- Offers, notifications, and alert preferences
- Feedback with star rating and history
- Driver companion (broadcast live GPS)
- English / Bangla UI
- Offline-friendly banners and resilient error handling

## Tech stack

| Layer | Technology |
|--------|------------|
| App | Flutter 3 · Dart · Provider |
| Auth | Firebase Authentication |
| Data | Cloud Firestore |
| Push | Firebase Cloud Messaging |
| Functions | Cloud Functions (TypeScript) |
| Maps | Google Maps Flutter · Geolocator |
| Design | Syne + IBM Plex Sans · teal/amber brand |

## Quick start

```bash
git clone https://github.com/Hasin-99/StudentMove_Flutter_App.git
cd StudentMove_Flutter_App
flutter pub get
```

Configure Firebase (see [`docs/firebase_setup.md`](docs/firebase_setup.md)):

```bash
cp .firebaserc.example .firebaserc
# Generate lib/firebase_options_dev.dart and lib/firebase_options_prod.dart
# with flutterfire configure
```

Run:

```bash
flutter run --dart-define=FIREBASE_FLAVOR=dev
```

Optional emulators:

```bash
firebase emulators:start
flutter run --dart-define=FIREBASE_FLAVOR=dev --dart-define=USE_FIREBASE_EMULATOR=true
```

Production flavor:

```bash
flutter run --dart-define=FIREBASE_FLAVOR=prod
```

## Project layout

```
lib/                 Flutter app (screens, providers, services, theme)
android/ ios/ …      Platform runners
functions/           Cloud Functions
firestore.rules      Security rules
docs/                Setup, security, always-live guide
admin/               Admin helpers (Firebase-side)
```

## Docs

| Doc | Purpose |
|-----|---------|
| [`docs/BUILD_REFERENCE.md`](docs/BUILD_REFERENCE.md) | Architecture & how pieces fit |
| [`docs/firebase_setup.md`](docs/firebase_setup.md) | Firebase / FlutterFire setup |
| [`docs/ALWAYS_LIVE.md`](docs/ALWAYS_LIVE.md) | Keep Firebase (and related web) live |
| [`docs/security_checklist.md`](docs/security_checklist.md) | Pre-release security |
| [`docs/firebase_contract_mapping.md`](docs/firebase_contract_mapping.md) | Data contracts |

## Team

StudentMove — Smart Transport Solution · **Daffodil International University**

| Member | ID |
|--------|-----|
| Md. Shadman Hasin | 0242220005101462 |
| Md. Shadman Tahsin | 0242220005101461 |

## License

Private / academic project — all rights reserved by the team unless otherwise stated.
