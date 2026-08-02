# trip_io — Yaoundé Travel Companion (Phase 1 Complete)

Flutter frontend for **trip_io**: explore, plan, and navigate real
destinations around Yaoundé, Cameroon. Talks to the `trip_io_backend`
FastAPI monolith. Builds for **Android, Web, and Windows**.

## Features

- **Accounts** — email/password or Google Sign-In, editable profile (bio,
  avatar, areas of interest), English/French localization
- **Destinations** — search and filter a curated catalog by interest tag,
  view details (photos, opening hours, entry fees, tips, nearby eat/stay
  picks), rate 1–5 stars, and read/post threaded comments (with an unseen-
  comments indicator on both the detail page and destination cards); suggest
  a new destination with a photo and a tap-to-place map location, reviewed
  by an admin before it goes live
- **Favorites** — save destinations for later from anywhere in the app
- **Itineraries** — build a multi-day plan from a set of destinations; the
  backend auto-generates a scheduled timeline with travel buffers
- **Map & routing** — an interactive Yaoundé map (MapLibre vector tiles on
  Android/Web, a flutter_map raster fallback on Windows, since MapLibre has
  no Windows plugin) with turn-by-turn walking/cycling/driving directions,
  live location with heading, and a one-tap "Start itinerary" that routes
  from your current location through every stop in order
- **AI assistant** — a Groq-powered chat with starter suggestions, plus a
  one-tap "explain this place" on any destination
- **Read aloud** — text-to-speech for a destination's details and for its
  AI-generated explanation, independently
- **Admin** — destination moderation and catalog management lives in a
  separate web dashboard (`trip_io_backend/website/admin.html`), not in this
  app

## Setup

```powershell
cd trip_io
flutter pub get
```

## Run

Web:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

Windows:

```powershell
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8000
```

Android emulator:

```powershell
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

You can also change the backend URL from the login screen. Google Sign-In
additionally needs `--dart-define=GOOGLE_WEB_CLIENT_ID=<your-oauth-client-id>`
on Web/Android.

## Quality checks

```powershell
flutter analyze
flutter test
```

## CI/CD

`jenkinsfile` defines a two-agent pipeline: a Windows agent builds and
deploys the Windows installer, and the Linux/VPS agent builds and deploys
the Android APK and Flutter web app - all three land on the backend's public
downloads page automatically on every push to `main`.
