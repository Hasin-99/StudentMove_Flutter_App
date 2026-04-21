# Firebase Security Checklist

## Required before production deploy

- Firestore rules deployed from `firestore.rules`.
- Firestore composite indexes deployed from `firestore.indexes.json`.
- Storage rules deployed from `storage.rules`.
- App Check enabled for Android and iOS apps.
- App Check enforcement verified after debug rollout.
- Email/password auth policy enforced in Firebase Authentication.
- Admin role assigned using custom claims only from secure environment.
- Cloud Functions deployed from `functions/src/index.ts`.

## Emulator validation

Run before merge:

```bash
firebase use studentmove-dev
firebase emulators:start
```

Validate:

- Student user can read own `users/{uid}` and `userPreferences/{uid}`.
- Student user cannot write `announcements`, `schedules`, or `liveBuses`.
- Student user can read and write only their own `chatRooms/{uid}/messages`.
- Admin role can perform privileged writes and callable workflows.

## Monitoring

- Enable Crashlytics and Firebase console alerts.
- Monitor Firestore read/write volume and query latency.
- Track function error rate and cold starts.
- Monitor FCM delivery and token churn (`users.fcmTokens`).
