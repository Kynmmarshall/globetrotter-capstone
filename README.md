# GlobeTrotter Frontend (`trip_io`)

Responsive Flutter frontend for the GlobeTrotter monolith backend.

## Features

- Login/Register with backend JWT endpoints
- Destination search (`GET /destinations`)
- Personalized recommendations (`GET /recommendations`)
- Itinerary creation and listing (`POST/GET /itineraries`)
- Adaptive UI:
	- Phone: bottom navigation
	- Tablet/Desktop/Web/Windows: navigation rail

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

You can also change the backend URL from the login screen.

## Quality checks

```powershell
flutter analyze
flutter test
```
