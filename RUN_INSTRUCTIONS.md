# কিভাবে StudentMove App রান করবেন

## সমস্যা: "No supported devices connected"

যদি আপনি `flutter run` চালান এবং "No supported devices connected" দেখেন, তাহলে নিচের সমাধানগুলো দেখুন:

## সমাধান 1: Web Browser এ রান করুন (সবচেয়ে সহজ)

```bash
cd E:\StudentMove_Flutter_App
flutter run -d chrome
```

অথবা Edge browser এ:
```bash
flutter run -d edge
```

## সমাধান 2: Android Emulator Setup করুন

### Step 1: Android Studio Install করুন
1. https://developer.android.com/studio থেকে Android Studio download করুন
2. Install করুন
3. Android Studio খুলুন এবং SDK Manager থেকে:
   - Android SDK Platform
   - Android SDK Platform-Tools
   - Android Emulator
   Install করুন

### Step 2: Emulator তৈরি করুন
1. Android Studio → Tools → Device Manager
2. "Create Device" ক্লিক করুন
3. একটি device select করুন (যেমন: Pixel 5)
4. System Image download করুন (Android 13 বা নতুন)
5. Finish করুন

### Step 3: Emulator Start করুন
```bash
flutter emulators --launch <emulator-id>
```

অথবা Android Studio থেকে Device Manager এ emulator start করুন

### Step 4: App Run করুন
```bash
cd E:\StudentMove_Flutter_App
flutter run
```

## সমাধান 3: Physical Android Device ব্যবহার করুন

1. আপনার Android phone এ Developer Options enable করুন:
   - Settings → About Phone
   - Build Number এ 7 বার tap করুন

2. USB Debugging enable করুন:
   - Settings → Developer Options
   - USB Debugging on করুন

3. Phone USB দিয়ে computer এর সাথে connect করুন

4. Run করুন:
```bash
cd E:\StudentMove_Flutter_App
flutter run
```

## সমাধান 4: Windows Desktop এ Run করুন

```bash
cd E:\StudentMove_Flutter_App
flutter create . --platforms=windows
flutter run -d windows
```

**Note:** Windows platform এর জন্য Visual Studio প্রয়োজন

## Quick Commands

```bash
# Web এ run করুন (Chrome)
flutter run -d chrome

# Web এ run করুন (Edge)
flutter run -d edge

# Available devices দেখুন
flutter devices

# Emulators list দেখুন
flutter emulators

# Emulator start করুন
flutter emulators --launch <emulator-id>
```

## Troubleshooting

### Issue: "Chrome not found"
**Solution:** Chrome browser install করুন

### Issue: "Android SDK not found"
**Solution:** 
```bash
flutter doctor --android-licenses
```
Accept all licenses (y press করুন)

### Issue: "No devices found"
**Solution:**
1. Android Emulator start করুন
2. অথবা physical device connect করুন
3. `flutter devices` command run করে check করুন

## Demo Login Credentials

- **Email**: student@example.com
- **Password**: password123
