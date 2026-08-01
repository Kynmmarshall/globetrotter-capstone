# GlobeTrotter — Travel Recommendation & Itinerary Platform

GlobeTrotter is a full-stack travel assistant that lets users search destinations, receive personalized recommendations, plan and delete itineraries, view destinations on an interactive map with turn-by-turn directions, and interact with an AI travel assistant (with read-aloud support) — plus social features like ratings, comments, favorites, and profile avatars, community-submitted destinations reviewed through an admin moderation panel, Google Sign-In, and public usage analytics. The repository contains two independently deployable projects:

| Project | Description | Stack |
|---|---|---|
| [`backend/`](backend/) | REST API monolith serving auth, destinations, recommendations, and itineraries | Python, FastAPI, JWT |
| [`frontend/`](frontend/) | Cross-platform client (mobile, web, desktop) | Flutter/Dart |

> **Course context:** This is the Phase 1 (Monolith) deliverable of a semester-long capstone (CS 4122) that progresses through Monolith → Microservices → Cloud Deployment → Resilience. The current architecture intentionally favors simplicity (a single API service, JSON-file storage) over scalability; later phases replace these with distributed, production-grade infrastructure.

## Live Deployment

The Phase 1 monolith is deployed on a VPS and reachable at **[https://trip-io.duckdns.org](https://trip-io.duckdns.org)**. Client builds default to this URL, so `flutter run`/release builds work against the real API out of the box with no configuration required.

| Surface | URL | Notes |
|---|---|---|
| Marketing site + downloads | https://trip-io.duckdns.org | Landing page with Windows/Android download links |
| Public stats | https://trip-io.duckdns.org/stats.html | Live visitor/usage stats (bilingual EN/FR), backed by `GET /stats/public` |
| Web app | https://trip-io.duckdns.org/app/ | The Flutter app running directly in the browser |
| API | https://trip-io.duckdns.org | Same host, serves `/register`, `/login`, `/destinations`, etc. |
| API docs (Swagger UI) | https://trip-io.duckdns.org/docs | Interactive request/response reference |
| Windows download | https://trip-io.duckdns.org/downloads/trip_io_windows.exe | Packaged desktop build |
| Android download | https://trip-io.duckdns.org/downloads/trip_io.apk | Installable APK |

---

## Table of Contents

- [Live Deployment](#live-deployment)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Backend Setup](#backend-setup)
  - [Frontend Setup](#frontend-setup)
- [API Reference](#api-reference)
- [Configuration](#configuration)
- [Testing](#testing)
- [Containers & CI/CD](#containers--cicd)
- [Data Storage](#data-storage)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Architecture

```
                 ┌────────────────────────┐
                 │   Flutter Client        │
                 │  (Web / Android / iOS /  │
                 │   Windows / macOS /Linux)│
                 └───────────┬─────────────┘
                             │ HTTPS (JSON, JWT bearer)
                             ▼
                 ┌────────────────────────┐
                 │   FastAPI Monolith      │
                 │  (backend/app)          │
                 │  - Auth (JWT + bcrypt)  │
                 │  - Destinations         │
                 │  - Recommendations      │
                 │  - Itineraries          │
                 └───────────┬─────────────┘
                             ▼
                 ┌────────────────────────┐
                 │  JSON file data store   │
                 │  (backend/data/data.json)│
                 └────────────────────────┘
```

The backend also serves a static marketing site and a compiled Flutter web build directly from FastAPI (`website/`, `website/app`, `website/downloads`), so the whole product can be hosted from a single process during Phase 1.

## Repository Structure

```
globetrotter-capstone/
├── backend/                 # FastAPI monolith
│   ├── app/
│   │   ├── main.py          # Route definitions & app wiring
│   │   ├── auth.py          # JWT issuing/validation, password hashing
│   │   ├── crud.py          # Data access / business logic
│   │   ├── data.py          # JSON-file read/write with a thread lock
│   │   └── schemas.py       # Pydantic request/response models
│   ├── data/                # Runtime JSON data store (gitignored)
│   ├── scripts/              # Destination discovery/image-vetting tooling (not run in prod)
│   ├── static/               # Uploaded/served assets (e.g. destination images)
│   ├── website/              # Static marketing site + hosted web/app builds
│   ├── tests/                # Pytest + httpx API tests
│   ├── Dockerfile / docker-compose.yml
│   └── requirements.txt
│
└── frontend/                 # Flutter client ("trip_io")
    ├── lib/
    │   ├── main.dart / app.dart
    │   ├── screens/           # Auth, dashboard, destinations, itineraries, profile
    │   ├── services/          # ApiClient, session controller, itinerary scheduler
    │   ├── models/            # Data models (incl. shared interest-tag vocabulary)
    │   ├── themes/             # App theming
    │   └── l10n/                # Localization (English, French)
    ├── assets/
    ├── Dockerfile / nginx.conf   # Web-release container image
    ├── jenkinsfile               # CI/CD: builds + deploys Windows/Android/Web to the VPS
    └── pubspec.yaml
```

## Prerequisites

| Tool | Version | Used for |
|---|---|---|
| [Python](https://www.python.org/) | 3.10+ | Backend API |
| [pip](https://pip.pypa.io/) | latest | Backend dependencies |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | 3.12+ (Dart ^3.12.1) | Frontend client |
| A JSON-capable editor | — | Editing seed data |

## Getting Started

Clone the repository, then set up each project as described below. This is only needed for local development/testing — the [live deployment](#live-deployment) is already running and is what client builds talk to by default.

### Backend Setup

```powershell
cd backend

# Create and activate a virtual environment
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# Run the API with hot reload
uvicorn app.main:app --reload --port 8000
```

Once running:

- Interactive API docs (Swagger UI): http://localhost:8000/docs
- Alternative docs (ReDoc): http://localhost:8000/redoc
- Static marketing site: http://localhost:8000/

### Frontend Setup

```powershell
cd frontend

# Fetch packages
flutter pub get
```

With no arguments, the app defaults to the live deployment at `https://trip-io.duckdns.org`:

```powershell
flutter run -d chrome
```

To point the client at a local backend instead, override `API_BASE_URL`:

```powershell
# Web (Chrome)
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000

# Windows desktop
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8000

# Android emulator (host loopback is 10.0.2.2, not localhost)
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

The backend URL can also be changed at runtime from the app's login screen, so `--dart-define` is a convenience default rather than a hard requirement.

## API Reference

Base URL: `https://trip-io.duckdns.org` (production) or `http://localhost:8000` (local dev)

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/health` | — | Liveness check (used by Docker/orchestration health checks) |
| `POST` | `/register` | — | Create a user account (optionally with `interests`), returns a JWT |
| `POST` | `/login` | — | Authenticate, returns a JWT |
| `POST` | `/auth/google` | — | Exchange a Google ID token for a JWT, creating the account on first sign-in |
| `GET` | `/me` | Bearer token | Get the current user's profile (username, email, interests, avatar, favorites) |
| `PUT` | `/me/interests` | Bearer token | Replace the current user's interest tags |
| `POST` | `/me/avatar` | Bearer token | Upload a profile picture (JPEG/PNG/WEBP/GIF, max 5MB) |
| `GET` | `/me/favorites` | Bearer token | List the current user's favorited destinations |
| `POST` | `/me/favorites/{destination_id}` | Bearer token | Add a destination to favorites |
| `DELETE` | `/me/favorites/{destination_id}` | Bearer token | Remove a destination from favorites |
| `GET` | `/destinations?q=` | Optional | Search/list approved destinations by name or tag; includes rating average/count, plus the viewer's own rating if signed in |
| `GET` | `/destinations/{id}` | Optional | Get a single approved destination, with its rating summary |
| `PUT` | `/destinations/{id}/rating` | Bearer token | Rate a destination 1-5 stars |
| `DELETE` | `/destinations/{id}/rating` | Bearer token | Clear your own rating on a destination |
| `POST` | `/destinations/submit` | Bearer token | Propose a new destination; enters a `pending` moderation queue |
| `GET` | `/me/submissions` | Bearer token | List destinations you've submitted, with their moderation status |
| `POST` | `/destinations/{id}/image` | Bearer token | Attach/replace a destination's photo (only its submitter or an admin) |
| `GET` | `/destinations/{id}/comments` | Bearer token | Get threaded comments for a destination, with the viewer's own vote on each |
| `POST` | `/destinations/{id}/comments` | Bearer token | Post a comment or reply (`parent_id`), max 2000 characters |
| `POST` | `/comments/{id}/vote` | Bearer token | Upvote/downvote/clear your vote on a comment (`direction`: `up`/`down`/`none`) |
| `GET` | `/recommendations` | Bearer token | Personalized destinations, ranked by overlap with the user's interest tags (falls back to popular picks if none are set) |
| `POST` | `/itineraries` | Bearer token | Create an itinerary (title, destinations, optional `schedule`, `start_date`/`end_date`) |
| `GET` | `/itineraries` | Bearer token | List itineraries owned by the current user |
| `DELETE` | `/itineraries/{id}` | Bearer token | Delete an itinerary you own |
| `POST` | `/ai/chat` | Bearer token | Chat with the in-app AI travel assistant (Groq-backed, grounded in the real destination catalog) |
| `POST` | `/ai/explain/{destination_id}` | Bearer token | Get (and cache) an AI-generated explanation of a destination |
| `GET` | `/stats/public` | — | Aggregated, anonymized usage stats (total users, active today/this week, 14-day daily-active series, top sections) for the public stats page, sourced from Matomo server-side and cached for 60s |
| `GET`/`PATCH`/`POST`/`DELETE` | `/admin/destinations[/{id}]` | Bearer token (admin) | Review/approve/reject/edit, directly create, or delete destinations — restricted to accounts with `role: "admin"` in the data store |
| `POST` | `/route` | Bearer token | Turn-by-turn directions between 2+ waypoints (`driving-car`/`foot-walking`/`cycling-regular`), proxied server-side to OpenRouteService |

Destinations also carry richer detail fields — `nearby` (nearby hotels/restaurants), `opening_hours`, `entry_fee`, `tips`, `lat`/`lon` coordinates, and a `comment_count` (used client-side to show a "new comments" indicator) — returned by both `/destinations` and `/recommendations`. The interest-tag vocabulary used for filtering/recommendations is kept in sync between backend seed data and [`frontend/lib/models/interest_tags.dart`](frontend/lib/models/interest_tags.dart). A destination's `status` (`approved`/`pending`/`rejected`) governs whether it's publicly visible; only `approved` destinations are returned by the public-facing endpoints. There's a lightweight, browser-based admin panel at `/admin.html` on the deployed site for moderating submissions — access is gated by JWT + the account's `role`, not a separate login.

Authenticated requests must include:

```
Authorization: Bearer <access_token>
```

### Example: Register and create an itinerary

```powershell
# Register
curl -X POST http://localhost:8000/register `
  -H "Content-Type: application/json" `
  -d '{"username":"alice","password":"secret","email":"alice@example.com"}'

# Create an itinerary (replace TOKEN with the access_token from above)
curl -X POST http://localhost:8000/itineraries `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer TOKEN" `
  -d '{"title":"Yaounde Weekend","destinations":["d1","d2"]}'
```

Full request/response schemas are available live via the Swagger UI at `/docs`.

## Configuration

### Backend environment variables

| Variable | Default | Purpose |
|---|---|---|
| `JWT_SECRET` | `dev-secret-change-me` | Secret used to sign/verify JWTs — **must** be overridden in any non-local environment |
| `GLOBETROTTER_DATA_PATH` | `backend/data/data.json` | Path to the JSON data store (also used to isolate test runs) |
| `MATOMO_URL` | `https://trip-io-analytics.duckdns.org` | Base URL of the Matomo instance queried for `/stats/public` |
| `MATOMO_API_TOKEN` | *(unset)* | Matomo API token used server-side to fetch stats; without it, `/stats/public` degrades to zeros instead of failing |
| `MATOMO_SITE_ID` | `1` | Matomo site ID to report on |
| `GROQ_API_KEY` | *(unset)* | API key for Groq's chat completions API, powering `/ai/chat` and `/ai/explain`; without it, both endpoints return `503` |
| `GROQ_MODEL` | `llama-3.3-70b-versatile` | Groq model used for the AI assistant |
| `GOOGLE_OAUTH_CLIENT_ID` | *(unset)* | Expected audience for Google Sign-In ID tokens verified by `/auth/google`; without it, that endpoint returns `401` |
| `ORS_API_KEY` | *(unset)* | API key for OpenRouteService, powering `/route`; without it, the endpoint fails with a "not configured" error |

Set them before starting the server, e.g.:

```powershell
$env:JWT_SECRET = "a-long-random-production-secret"
uvicorn app.main:app --port 8000
```

### Frontend configuration

| Define | Default | Purpose |
|---|---|---|
| `API_BASE_URL` | `https://trip-io.duckdns.org` | Backend base URL, passed via `--dart-define`; override to `http://localhost:8000` (or `http://10.0.2.2:8000` on the Android emulator) for local dev |
| `GOOGLE_WEB_CLIENT_ID` | *(unset)* | Google OAuth web client ID for Google Sign-In, passed via `--dart-define`; required for the Google Sign-In button to work on Android/web |

## Testing

**Backend** (pytest + httpx, isolated against a temp data file):

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
pytest
```

**Frontend** (static analysis + widget/unit tests):

```powershell
cd frontend
flutter analyze
flutter test
```

## Containers & CI/CD

Both services can also run in Docker, as an alternative to local `venv`/`flutter run` development:

```powershell
cd backend
docker compose up --build
# Backend:  http://localhost:8000  (website, API, /docs)
# Frontend: http://localhost:8081  (Flutter web build via Nginx)
```

`backend/docker-compose.yml` builds the backend from `backend/Dockerfile` and the frontend web build from `../frontend` (`frontend/Dockerfile`, served via `nginx.conf`), assuming the two project folders are siblings on disk. The frontend's `API_BASE_URL` build arg must point somewhere the *browser* can reach — override it for anything other than local dev (see comments in the compose file).

The live deployment at `trip-io.duckdns.org` is **not** container-based — it runs directly on the VPS via systemd + Nginx, kept up to date by a Jenkins pipeline (`frontend/jenkinsfile`) that triggers on every push to `main` and:

1. Builds and deploys the Windows installer from a Windows build agent (via SCP).
2. Runs `flutter analyze`/`flutter test`, then builds and deploys the Android APK and the Flutter web release directly onto the VPS's `website/downloads/` and `website/webapp/` (the same directories served by the backend, see [Architecture](#architecture)).

## Data Storage

Phase 1 intentionally uses a single JSON file (`backend/data/data.json`) as the datastore, guarded by a Python `threading.Lock` for basic write safety. This keeps the monolith dependency-free and easy to run locally, at the cost of concurrency and durability guarantees suitable only for development/demo use. The file is excluded from version control (`backend/.gitignore`); seed it manually with `users`, `destinations`, and `itineraries` arrays before first run, or let `/register` create the first user.

## Roadmap

| Phase | Focus | Status |
|---|---|---|
| 1. Monolith | Single FastAPI service, JSON storage, working REST API | ✅ Current |
| 2. Microservices | Service decomposition, inter-service communication, API gateway | Planned |
| 3. Cloud Deployment | Containerization, load balancing, auto-scaling | Planned |
| 4. Resilience | Caching, message queues, circuit breakers, fault tolerance | Planned |

See [CHANGELOG.md](CHANGELOG.md) for what's been implemented in each phase so far.

## Contributing

1. Create a feature branch from `main`.
2. Make your changes, adding/updating tests where relevant (`pytest` for backend, `flutter test` for frontend).
3. Run `flutter analyze` / `pytest` locally before opening a PR.
4. Open a pull request describing the change and its motivation.

## License

No license file is currently included in this repository; all rights reserved by the author unless a license is added..
