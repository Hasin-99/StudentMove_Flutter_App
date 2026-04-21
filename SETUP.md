# Setup Instructions for StudentMove Flutter App

## Initial Setup

1. **Install Flutter**
   - Download Flutter SDK from https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH

2. **Verify Installation**
   ```bash
   flutter doctor
   ```

3. **Get Dependencies**
   ```bash
   flutter pub get
   ```

## Google Maps Setup (Required for Bus Tracking)

### Android Setup

1. Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)

2. Add the API key to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <manifest>
     <application>
       <meta-data
         android:name="com.google.android.geo.API_KEY"
         android:value="YOUR_API_KEY_HERE"/>
     </application>
   </manifest>
   ```

### iOS Setup

1. Add the API key to `ios/Runner/AppDelegate.swift`:
   ```swift
   GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
   ```

## Running the App

### Run on Android
```bash
flutter run
```

### Run on iOS
```bash
flutter run
```

### Build APK
```bash
flutter build apk
```

### Build iOS
```bash
flutter build ios
```

## Demo Credentials

- Email: `student@example.com`
- Password: `password123`

## Features Implemented

✅ Splash Screen
✅ Sign In / Sign Up
✅ Home Dashboard
✅ Bus Tracking (requires Google Maps API key)
✅ Next Bus Arrival
✅ Notifications
✅ Chat Support
✅ Offers & Subscriptions
✅ Settings
✅ Booking

## Notes

- The app uses demo data for now
- Backend integration can be added later
- Authentication is handled locally with SharedPreferences

