# Keep StudentMove always live

StudentMove has **two live surfaces**:

| Surface | Repo | Host | Purpose |
|---|---|---|---|
| **Flutter app** (Android/iOS/web) | `studentmove_flutter_app` | **Firebase** (Auth, Firestore, Functions, FCM) | Student mobile experience |
| **Web/PWA + admin/driver** | `StudentMove-Smart-Transport-Solution-for-Dhaka` | **Render** | Public web, SSLCommerz, admin, driver GPS |

Flutter does **not** run on Render. Render keeps the Laravel/PWA site online 24/7. Firebase keeps the Flutter backend live 24/7.

---

## A) Keep Flutter backend always live (Firebase)

### 1. Use the production Firebase project

```bash
cd studentmove_flutter_app
cp .firebaserc.example .firebaserc   # set prod project id
# Ensure lib/firebase_options_prod.dart matches Console
```

### 2. Deploy rules, indexes, functions

```bash
firebase use prod
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

### 3. Seed required collections (once)

In Firebase Console → Firestore, ensure these exist (or use your seed scripts):

- `schedules`
- `announcements`
- `offers` (optional; app has demo fallback)
- `liveBuses` (filled by Driver Console)

### 4. Run the app against prod

```bash
flutter pub get
flutter run --dart-define=FIREBASE_FLAVOR=prod
# Android release:
flutter build apk --release --dart-define=FIREBASE_FLAVOR=prod
```

### 5. Keep FCM / App Check healthy

- Enable Cloud Messaging in Firebase Console  
- For release builds, use Play Integrity / DeviceCheck (already wired)  
- Subscribe topic `all-users` is set in app code  

### 6. Monitoring (always-on checklist)

- Firebase Console → **Crashlytics** (optional add) / Auth / Firestore usage  
- Watch **Firestore rules** denials in Rules Playground  
- Confirm `liveBuses` documents update when a driver starts shift  

---

## B) Keep web StudentMove always live on Render

Repo: [StudentMove-Smart-Transport-Solution-for-Dhaka](https://github.com/Tahis-Fzs/StudentMove-Smart-Transport-Solution-for-Dhaka)  
Blueprint: `render.yaml` → service `studentmove-app-d866`  
URL pattern: `https://studentmove-app-d866.onrender.com`

### 1. Connect the GitHub repo to Render

1. Open [https://dashboard.render.com](https://dashboard.render.com)  
2. **New** → **Blueprint** (or Web Service)  
3. Select the Laravel StudentMove repo  
4. Confirm `render.yaml` is detected  

### 2. Set required environment variables

In Render → Service → **Environment**, set at least:

| Key | Notes |
|---|---|
| `APP_KEY` | `php artisan key:generate --show` then paste |
| `APP_URL` | your Render URL (`https://….onrender.com`) |
| `ADMIN_PASSWORD` | strong password |
| `FIREBASE_*` | same project as Flutter (API key, auth domain, project id, …) |
| `SSLCOMMERZ_*` | sandbox for demo; live creds for production |
| `DB_*` | sqlite path from yaml, or upgrade to Postgres |

Keep:

- `APP_ENV=production`  
- `APP_DEBUG=false`  
- `SESSION_SECURE_COOKIE=true`  

### 3. Deploy

- Push to the branch Render watches (usually `main`)  
- Or click **Manual Deploy** → **Deploy latest commit**  
- Wait until health check `/health.html` is green  

### 4. Free-tier sleep vs always-on

Render **free** web services **spin down after idle**. To stay **always live**:

1. Upgrade the web service to a **paid instance** (Starter or higher) — this prevents cold sleep  
2. Or keep free tier and accept ~30–60s cold start after idle  

Recommended for demos/thesis: **Starter** plan + auto-deploy from `main`.

### 5. Optional keep-alive (only if you stay on free)

Use an external uptime ping every 5–10 minutes to `/health.html`  
(UptimeRobot, cron-job.org, GitHub Action).  
This reduces sleep but is not as reliable as a paid always-on instance.

### 6. Post-deploy smoke on Render

1. Open `/` — landing loads  
2. `/login` — Google/email auth  
3. `/next-bus-arrival` — schedule + map  
4. `/subscription` — plans + SSLCommerz sandbox  
5. `/driver/login` — PIN `driver123` (demo)  
6. `/admin/login` — admin password from env  

---

## C) End-to-end “always live” operating loop

Daily/weekly:

1. **Render** dashboard → service status green; last deploy succeeded  
2. **Firebase** console → Auth users growing; Firestore reads/writes normal  
3. Flutter release build points to `FIREBASE_FLAVOR=prod`  
4. Driver Console (Flutter) or Render `/driver` publishing GPS → students see live badges  
5. If Render redeploys, verify `APP_KEY` and Firebase env vars were **not wiped**  

---

## D) Local smoke before each release

```bash
cd studentmove_flutter_app
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=FIREBASE_FLAVOR=prod
```

Manual UI path:

1. Splash → Sign in  
2. Home rail: Live map / Book / Plans / Alerts / Chat  
3. Book a seat → see `SM…` code  
4. Chat → AI tab + Support tab  
5. Feedback submit  
6. Driver Console → Start shift → Live Track shows GPS badge  

---

## E) What lives where (quick mental model)

```
Students (Flutter) ──► Firebase Auth/Firestore/FCM  (always on)
Drivers (Flutter)  ──► liveBuses docs           (always on)
Web students/admin ──► Render Laravel/PWA       (always on if paid)
Payments (web)     ──► SSLCommerz via Render
```
