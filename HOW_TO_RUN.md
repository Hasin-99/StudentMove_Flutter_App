# How to Run StudentMove Flutter App

## Step 1: Install Flutter

### Windows Installation

1. **Download Flutter SDK**
   - Go to https://flutter.dev/docs/get-started/install/windows
   - Download the latest stable Flutter SDK (ZIP file)
   - Extract the ZIP file to a location like `C:\src\flutter`
   - **DO NOT** install Flutter in a path with spaces or special characters

2. **Add Flutter to PATH**
   - Open "Environment Variables" in Windows
   - Under "User variables", find "Path" and click "Edit"
   - Click "New" and add: `C:\src\flutter\bin` (or your Flutter installation path)
   - Click "OK" to save

3. **Verify Installation**
   - Open a **NEW** PowerShell or Command Prompt window
   - Run: `flutter --version`
   - You should see Flutter version information

4. **Run Flutter Doctor**
   ```bash
   flutter doctor
   ```
   - This will check your setup and show what's missing
   - Install any missing components (Android Studio, VS Code, etc.)

## Step 2: Install Required Tools

### Option A: Android Studio (Recommended for Android Development)

1. Download Android Studio from https://developer.android.com/studio
2. Install Android Studio
3. Open Android Studio and go through the setup wizard
4. Install Android SDK, Android SDK Platform-Tools, and Android Emulator

### Option B: VS Code (Lighter Alternative)

1. Download VS Code from https://code.visualstudio.com/
2. Install Flutter extension in VS Code
3. Install Dart extension in VS Code

## Step 3: Set Up Android Emulator (For Testing)

1. Open Android Studio
2. Go to Tools → Device Manager
3. Click "Create Device"
4. Select a device (e.g., Pixel 5)
5. Download a system image (e.g., Android 13)
6. Finish the setup

**OR** use a physical Android device:
- Enable Developer Options
- Enable USB Debugging
- Connect via USB

## Step 4: Navigate to Project Directory

```bash
cd E:\StudentMove_Flutter_App
```

## Step 5: Install Dependencies

```bash
flutter pub get
```

This will download all required packages listed in `pubspec.yaml`.

## Step 6: Check Connected Devices

```bash
flutter devices
```

You should see your emulator or connected device listed.

## Step 7: Run the App

### Run on Android Emulator/Device:
```bash
flutter run
```

### Run on Specific Device:
```bash
flutter run -d <device-id>
```

### Run in Release Mode:
```bash
flutter run --release
```

### Run with Hot Reload:
- Press `r` in the terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

## Troubleshooting

### Issue: "flutter: command not found"
**Solution**: 
- Make sure Flutter is added to PATH
- Restart your terminal/PowerShell
- Verify with: `flutter --version`

### Issue: "No devices found"
**Solution**:
- Start Android Emulator from Android Studio
- Or connect a physical device
- Run `flutter devices` to verify

### Issue: "Android license not accepted"
**Solution**:
```bash
flutter doctor --android-licenses
```
Accept all licenses by typing `y`

### Issue: "Gradle build failed"
**Solution**:
```bash
cd android
gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: "Google Maps not working"
**Solution**:
- Get Google Maps API key from https://console.cloud.google.com/
- Add to `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_API_KEY_HERE"/>
  ```
- For Flutter Web, add key to `web/index.html`:
  ```html
  <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY"></script>
  ```
- In Google Cloud Console, enable **Maps JavaScript API** and allow HTTP referrers:
  - `http://localhost:*/*`
  - `https://studentmove-adminpannel.vercel.app/*` (or your deployed app domain)

## Quick Start Commands Summary

```bash
# 1. Navigate to project
cd E:\StudentMove_Flutter_App

# 2. Get dependencies
flutter pub get

# 3. Check devices
flutter devices

# 4. Run app
flutter run

# 5. Build APK (for distribution)
flutter build apk
```

## Demo Credentials

When you run the app, use these credentials to sign in:
- **Email**: student@example.com
- **Password**: password123

## Additional Resources

- Flutter Documentation: https://flutter.dev/docs
- Flutter Cookbook: https://flutter.dev/docs/cookbook
- Dart Language Tour: https://dart.dev/guides/language/language-tour
