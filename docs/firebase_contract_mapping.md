# Firebase Contract Mapping

This document maps legacy REST contracts to Firebase data access contracts used by the Flutter app.

## Auth and User Profile

- Legacy: `POST /api/v1/auth/login`
  - Input: `email`, `password`
  - Firebase: `FirebaseAuth.signInWithEmailAndPassword`
  - Extra read: `users/{uid}` profile document
- Legacy: `POST /api/v1/users`
  - Input: `full_name`, `email`, `student_id`, `department`, `password`
  - Firebase:
    1) `FirebaseAuth.createUserWithEmailAndPassword`
    2) Create `users/{uid}` with profile fields
    3) Create `userPreferences/{uid}` if missing
- Legacy: `POST /api/v1/auth/reset-password`
  - Firebase: `FirebaseAuth.sendPasswordResetEmail`
- Legacy: `GET/POST /api/v1/users/preferences/routes`
  - Firebase: `userPreferences/{uid}.savedRoutes`

## Schedules

- Legacy: `GET /api/v1/schedules`
  - Legacy response: JSON array
  - Firebase source: collection `schedules`
  - App mapping fields:
    - `routeName`, `dayIndex`, `timeLabel`, `dateLabel`, `origin`, `busCode`, `whiteboardNote`, `universityTags`

## Announcements

- Legacy: `GET /api/v1/announcements?email&department&routes`
  - Legacy response: JSON array
  - Firebase source: collection `announcements`
  - App-side filter dimensions:
    - publish window (`publishAt <= now`, `expireAt` optional)
    - audience by `department`, `routes`, and global visibility

## Live Buses

- Legacy: `GET /api/v1/buses/live`
  - Legacy response: JSON array
  - Firebase source: collection `liveBuses`
  - App mapping fields:
    - `busCode`, `lat`, `lng`, `heading`, `speedKmph`, `updatedAt`

## Chat

- Legacy: `GET /api/v1/chat/messages?email=...`
- Legacy: `POST /api/v1/chat/messages`
  - Firebase source:
    - Room: `chatRooms/{roomId}` where `roomId == uid`
    - Messages: `chatRooms/{roomId}/messages/{messageId}`
  - App mapping fields:
    - `text`, `senderRole`, `createdAt`

## Production Constraints

- Sensitive auth state is not persisted in `SharedPreferences`; Firebase SDK session is source of truth.
- Firestore write access is constrained by Security Rules.
- Admin/privileged writes should flow through Cloud Functions or admin-only role rules.
