# Firebase Cutover and Rollout

## Pre-cutover

- Deploy rules, indexes, storage rules, and functions to `studentmove-dev`.
- Seed Firestore test data (`routes`, `schedules`, `announcements`, `liveBuses`).
- Validate auth, chat, schedule, announcement, and live tracking from app.

## Staged rollout

1. Internal QA build using `FIREBASE_FLAVOR=dev`.
2. Dogfood build with production Firebase project but restricted tester users.
3. Production rollout in phases (10% -> 50% -> 100%).

## Rollback

- Keep previous app binary and release lane.
- If severe issue appears:
  - Roll back app store rollout.
  - Revert latest rules/functions deploy.
  - Restore previous Firestore rules snapshot from source control.

## Post-cutover checks

- No runtime references to legacy REST endpoints.
- Auth sign-in/sign-up/reset succeeds.
- Chat messages persist and stream in real time.
- Live buses update from Firestore.
- Announcements and schedules load from Firestore.
