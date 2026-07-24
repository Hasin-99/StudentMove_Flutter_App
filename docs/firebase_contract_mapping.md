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

## Bookings

- Legacy: ride booking with seat counts / cancel
  - Firebase source: collection `bookings`
  - App mapping fields:
    - `userId`, `code`, `route`, `busNumber`, `from`, `to`, `travelDate`, `departureTime`, `seats`, `seatPreference`, `fare`, `status`

## Feedback

- Legacy: student feedback + admin reply
  - Firebase source: collection `feedback`
  - App mapping fields:
    - `userId`, `subject`, `message`, `rating`, `status`, `reply`

## Offers

- Legacy: active promotions
  - Firebase source: collection `offers`
  - App mapping fields:
    - `title`, `description`, `discountPercent`, `validUntil`, `isActive`

## Subscriptions

- Legacy plans: Weekly ৳350 / Monthly ৳1200 / Single ৳30
  - Firebase source: `subscriptions/{uid}` + `subscriptions/{uid}/invoices`
  - App mapping fields:
    - `planName`, `status`, `validUntil`, invoice `amount`, `paymentMethod`, `paidAt`

