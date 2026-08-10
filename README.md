# GlobeTrotter — Travel Recommendation & Itinerary Platform

GlobeTrotter is a full-stack travel assistant that lets users search destinations, receive personalized recommendations that skip places they've already planned to visit, and plan, edit, delete, and share itineraries (including a public web link and a "claim this trip" flow). It has an interactive map with turn-by-turn directions, live nearby amenities, and one-tap Yango ride booking; an AI travel assistant with read-aloud support and tappable destination links in its replies; and destination videos (YouTube/Facebook/TikTok, embedded on web). Social features include ratings, editable/threaded comments, favorites, profile avatars (with in-app cropping), notifications (moderation decisions and trip reminders), community-submitted destinations reviewed through a searchable admin moderation panel, Google Sign-In, forgot-password email recovery, light/dark theming, and public usage analytics. The repository contains two independently deployable projects:

| Project | Description | Stack |
|---|---|---|
| [`backend/`](backend/) | API Gateway + 3 microservices (User, Itinerary, Recommendation) behind RabbitMQ | Python, FastAPI, JWT |
| [`frontend/`](frontend/) | Cross-platform client (mobile, web, desktop) | Flutter/Dart |

> **Course context:** This is a semester-long capstone (CS 4122) that progresses through Monolith → Microservices → Cloud Deployment → Resilience. Phase 1 (a single FastAPI monolith) shipped first and ran the live deployment; Phase 2 decomposed it into an API Gateway and three independent services communicating over REST and RabbitMQ, running the exact same feature set. Once Phase 2 had proven itself in production, the Phase 1 monolith's code was retired from the repository rather than kept around unused — see [CHANGELOG.md](CHANGELOG.md) for that history.

## Live Deployment

The Phase 2 microservices stack is deployed on a VPS and reachable at **[https://trip-io.duckdns.org](https://trip-io.duckdns.org)**, running behind the API Gateway. Client builds default to this URL, so `flutter run`/release builds work against the real API out of the box with no configuration required.

| Surface | URL | Notes |
|---|---|---|
| Marketing site + downloads | https://trip-io.duckdns.org | Landing page with Windows/Android download links |
| Public stats | https://trip-io.duckdns.org/stats.html | Live visitor/usage stats (bilingual EN/FR), backed by `GET /stats/public` |
| Web app | https://trip-io.duckdns.org/app/ | The Flutter app running directly in the browser |
| API | https://trip-io.duckdns.org | Same host, serves `/register`, `/login`, `/destinations`, etc., proxied by the Gateway to whichever service owns each path |
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

Four services behind a single public entry point — the Phase 2 microservices decomposition, now the only backend (the Phase 1 monolith it replaced was retired from the repo once this stack had proven itself in production; see [CHANGELOG.md](CHANGELOG.md)):

```
                        ┌────────────────────────┐
                        │   Flutter Client /      │
                        │   Website               │
                        └───────────┬─────────────┘
                                    │ HTTPS
                                    ▼
                        ┌────────────────────────┐
                        │   API Gateway :8000     │  ← only public port
                        │  (reverse proxy + site) │
                        └──┬──────────┬─────────┬─┘
                    ┌──────┘          │         └──────┐
                    ▼                 ▼                ▼
          ┌──────────────┐  ┌──────────────────┐  ┌────────────────────────┐
          │ User Service │  │Itinerary Service  │  │ Recommendation Service │
          │    :8001     │  │      :8002        │  │         :8003          │
          │ auth/profile/│  │ itineraries,      │  │ destinations/ratings/  │
          │ favorites,   │  │ sharing/claiming  │  │ comments/AI/routing/   │
          │ notifications│  │                   │  │ admin/amenities        │
          └──────┬───────┘  └─────────┬─────────┘  └───────────┬────────────┘
                 │                     │                        │
                 │   sync REST, X-Internal-Token   ◄─────────────┘
                 │                     │
                 └──────────┬──────────┴──────────────────────────┐
                             ▼                                     ▼
                   ┌──────────────────┐                 own JSON data file each
                   │ RabbitMQ (async)  │◄── user.registered, itinerary.created,
                   │ trip_io.events    │    destination.rated/approved/rejected
                   └──────────────────┘
```

- **Gateway** (`backend/gateway/`): the only port published to the host/internet (`8000`). Forwards requests to the owning service based on path (`gateway/app/proxy.py`'s routing table) — every external URL is unchanged from the old monolith's, so the Flutter app and website never had to change beyond repointing `API_BASE_URL`. Also serves the marketing site, `/downloads`, `/app`, and `/stats/public` directly, since none of those cleanly belong to one service.
- **User Service** (`services/user_service/`): accounts, JWT + Google Sign-In auth, password reset (email), profile/avatar, favorites, notifications.
- **Itinerary Service** (`services/itinerary_service/`): itinerary CRUD, sharing/claiming.
- **Recommendation Service** (`services/recommendation_service/`): destination catalog + moderation, ratings, comments, interest-based recommendations, the AI assistant, routing, nearby amenities.
- **Synchronous inter-service calls**: e.g. Recommendation Service reads from User Service and Itinerary Service over internal-only REST endpoints (`/internal/...`), authenticated with a shared `X-Internal-Token` header — never a user's JWT. The Gateway explicitly refuses to proxy anything under `/internal`.
- **Asynchronous inter-service calls**: a RabbitMQ topic exchange (`trip_io.events`) carries domain events (`user.registered`, `itinerary.created`/`.updated`, `destination.rated`/`.approved`/`.rejected`). User Service's consumer turns moderation events into persisted notifications; publishing is fire-and-forget, so a RabbitMQ outage never fails the request that triggered the event.
- **Per-service data**: each service owns its own JSON file (`users.json`, `itineraries.json`, `destinations.json`) — still JSON, not a real database, but no shared mutable state between services.

## Repository Structure

```
globetrotter-capstone/
├── backend/
│   ├── gateway/               # API Gateway (single public entry point)
│   │   └── app/
│   │       ├── main.py        # Routing table wiring + website/static hosting
│   │       ├── proxy.py       # Path-based reverse proxy to the 3 services
│   │       └── stats.py       # /stats/public (Matomo + User Service user count)
│   ├── services/
│   │   ├── user_service/          # Auth, profile, interests, avatar, favorites, notifications
│   │   ├── itinerary_service/     # Itinerary CRUD, sharing/claiming
│   │   └── recommendation_service/  # Destinations, ratings, comments, AI, routing, amenities, admin
│   ├── scripts/               # migrate_data.py (historical) + destination-discovery tooling
│   ├── website/               # Static marketing site + admin dashboard + hosted web/app builds
│   ├── docker-compose.microservices.yml / update_microservices.sh
│   └── README.md              # Backend-specific architecture/setup detail
│
└── frontend/                 # Flutter client ("trip_io")
    ├── lib/
    │   ├── main.dart / app.dart
    │   ├── screens/           # Auth, dashboard, destinations, itineraries, profile, notifications...
    │   ├── services/          # ApiClient, session controller, itinerary scheduler
    │   ├── models/            # Data models (incl. shared interest-tag vocabulary)
    │   ├── themes/             # App theming (incl. light/dark)
    │   └── l10n/                # Localization (English, French)
    ├── assets/
    ├── Dockerfile / nginx.conf   # Web-release container image
    ├── jenkinsfile               # CI/CD: builds + deploys Windows/Android/Web to the VPS
    └── pubspec.yaml
```

## Prerequisites

| Tool | Version | Used for |
|---|---|---|
| [Docker](https://docs.docker.com/get-docker/) + Compose plugin | latest | Running the full backend stack (Gateway + 3 services + RabbitMQ) |
| [Python](https://www.python.org/) | 3.10+ | Running/testing an individual backend service outside Docker |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | 3.12+ (Dart ^3.12.1) | Frontend client |

## Getting Started

Clone the repository, then set up each project as described below. This is only needed for local development/testing — the [live deployment](#live-deployment) is already running and is what client builds talk to by default.

### Backend Setup

The whole backend is Docker Compose-based — there's no single process to `uvicorn --reload` anymore, since it's 4 services:

```powershell
cd backend
docker compose -f docker-compose.microservices.yml up --build
```

- Gateway (single public entry point, website, API): http://localhost:8000
- Third-party API keys (Groq, ORS, Google OAuth, SMTP, Matomo) are all optional — each feature just reports "not configured" until set, rather than crashing its service. Set them via a `.env` file in `backend/` (gitignored); see [Configuration](#configuration).

To iterate on a single service without Docker (faster reload loop), run it directly:

```powershell
cd backend/services/user_service   # or itinerary_service / recommendation_service / ../../gateway
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8001   # match the service's port; see docker-compose.microservices.yml
```

Each service also exposes its own interactive API docs at `/docs` when run this way (e.g. http://localhost:8001/docs) — the production Gateway does **not** proxy `/docs`, so this is a local-dev-only convenience.

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

Base URL: `https://trip-io.duckdns.org` (production) or `http://localhost:8000` (local dev, via the [Gateway](#architecture)).

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/health` | — | Liveness check (used by Docker/orchestration health checks) |
| `POST` | `/register` | — | Create a user account (optionally with `interests`), returns a JWT |
| `POST` | `/login` | — | Authenticate, returns a JWT |
| `POST` | `/auth/google` | — | Exchange a Google ID token for a JWT, creating the account on first sign-in |
| `POST` | `/auth/request-password-reset` | — | Email a password reset code, if the username/email matches an account (response is identical either way) |
| `POST` | `/auth/reset-password` | — | Complete a password reset with the emailed code |
| `GET` | `/me` | Bearer token | Get the current user's profile (username, email, interests, avatar, favorites) |
| `PUT` | `/me/interests` | Bearer token | Replace the current user's interest tags |
| `POST` | `/me/avatar` | Bearer token | Upload a profile picture (JPEG/PNG/WEBP/GIF, max 5MB) |
| `GET` | `/me/favorites` | Bearer token | List the current user's favorited destinations |
| `POST` | `/me/favorites/{destination_id}` | Bearer token | Add a destination to favorites |
| `DELETE` | `/me/favorites/{destination_id}` | Bearer token | Remove a destination from favorites |
| `GET` | `/me/notifications` | Bearer token | List notifications (moderation decisions on your submissions + upcoming trip reminders) |
| `POST` | `/me/notifications/{id}/read` | Bearer token | Mark a notification as read |
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
| `PATCH` | `/comments/{id}` | Bearer token | Edit your own comment (within 5 minutes of posting) |
| `DELETE` | `/comments/{id}` | Bearer token | Delete your own comment (within 5 minutes, and only if it has no replies) |
| `GET` | `/recommendations` | Bearer token | Personalized destinations, ranked by interest-tag overlap and excluding destinations already in one of your itineraries |
| `POST` | `/itineraries` | Bearer token | Create an itinerary (title, destinations, optional `schedule`, `start_date`/`end_date`) |
| `GET` | `/itineraries` | Bearer token | List itineraries owned by the current user |
| `PATCH` | `/itineraries/{id}` | Bearer token | Edit an itinerary you own |
| `DELETE` | `/itineraries/{id}` | Bearer token | Delete an itinerary you own |
| `POST`/`DELETE` | `/itineraries/{id}/share` | Bearer token | Create/revoke a public share link for an itinerary |
| `GET` | `/shared/itineraries/{token}` | — | Public, unauthenticated view of a shared itinerary (trimmed, no viewer-specific data) |
| `POST` | `/itineraries/claim/{token}` | Bearer token | Copy a shared itinerary into your own account |
| `POST` | `/ai/chat` | Bearer token | Chat with the in-app AI travel assistant (Groq-backed, grounded in the real destination catalog); optional `language_code` (`en`/`fr`) forces the reply language |
| `POST` | `/ai/explain/{destination_id}` | Bearer token | Get (and cache per language) an AI-generated explanation of a destination |
| `GET` | `/amenities?categories=` | Bearer token | Nearby hospitals/pharmacies/fuel/hotels/banks/police across Yaoundé, live from OpenStreetMap (Overpass), disk-cached and refreshed in the background |
| `GET` | `/stats/public` | — | Aggregated, anonymized usage stats (total users, active today/this week, 14-day daily-active series, top sections) for the public stats page, sourced from Matomo server-side and cached for 60s |
| `GET`/`PATCH`/`POST`/`DELETE` | `/admin/destinations[/{id}]` | Bearer token (admin) | Review/approve/reject/edit, directly create, or delete destinations — restricted to accounts with `role: "admin"` in the data store |
| `POST` | `/route` | Bearer token | Turn-by-turn directions through 2+ waypoints (`driving-car`/`foot-walking`/`cycling-regular`), with a per-leg distance/duration breakdown, proxied server-side to OpenRouteService (retried on transient failures) |

Destinations also carry richer detail fields — `nearby` (nearby hotels/restaurants), `opening_hours`, `entry_fee`, `tips`, `price_tier`, `video_url` (YouTube/Facebook/TikTok, played in-app), `lat`/`lon` coordinates, and a `comment_count` (used client-side to show a "new comments" indicator) — returned by both `/destinations` and `/recommendations`. The interest-tag vocabulary used for filtering/recommendations is kept in sync between backend seed data and [`frontend/lib/models/interest_tags.dart`](frontend/lib/models/interest_tags.dart). A destination's `status` (`approved`/`pending`/`rejected`) governs whether it's publicly visible; only `approved` destinations are returned by the public-facing endpoints. There's a lightweight, browser-based admin panel at `/admin.html` on the deployed site — with its own destination search — for moderating submissions; access is gated by JWT + the account's `role`, not a separate login. AI chat replies may reference destinations as `[[Name|id]]`, which the app renders as tappable links straight to that destination's detail page.

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

Full request/response schemas are available live via each service's own Swagger UI when run locally (see [Backend Setup](#backend-setup)) — the production Gateway doesn't proxy `/docs`.

## Configuration

### Backend environment variables

Every third-party integration below is optional — the feature it powers just reports "not configured" instead of crashing its service. Amenities (OpenStreetMap Overpass) needs no key at all.

| Variable | Default | Purpose | Service |
|---|---|---|---|
| `JWT_SECRET` | `dev-secret-change-me` | Signs/verifies JWTs — **must** be overridden in any non-local environment | shared |
| `INTERNAL_SERVICE_TOKEN` | `dev-internal-token-change-me` | Shared secret authenticating service-to-service `/internal/*` calls — **must** be overridden in any non-local environment | shared |
| `RABBITMQ_URL` | `amqp://guest:guest@localhost:5672/` | RabbitMQ connection string used to publish/consume domain events | shared |
| `MATOMO_URL` | `https://trip-io-analytics.duckdns.org` | Base URL of the Matomo instance queried for `/stats/public` | gateway |
| `MATOMO_API_TOKEN` | *(unset)* | Matomo API token; without it, `/stats/public` degrades to zeros instead of failing | gateway |
| `MATOMO_SITE_ID` | `1` | Matomo site ID to report on | gateway |
| `GOOGLE_OAUTH_CLIENT_ID` | *(unset)* | Expected audience for Google Sign-In ID tokens; without it, `/auth/google` returns `401` | user_service |
| `SMTP_HOST` / `SMTP_PORT` / `SMTP_USER` / `SMTP_PASSWORD` / `SMTP_FROM_ADDRESS` | *(unset)*, `587` | SMTP credentials for password-reset emails; without them, the reset code is logged server-side instead of emailed | user_service |
| `PUBLIC_SITE_URL` | `https://trip-io.duckdns.org` | Builds the logo image URL embedded in password-reset emails | user_service |
| `GROQ_API_KEY` | *(unset)* | Powers `/ai/chat` and `/ai/explain`; without it, both return `503` | recommendation_service |
| `GROQ_MODEL` | `llama-3.3-70b-versatile` | Groq model used for the AI assistant | recommendation_service |
| `ORS_API_KEY` | *(unset)* | Powers `/route`; without it, the endpoint fails with a "not configured" error | recommendation_service |
| `USER_SERVICE_URL` / `ITINERARY_SERVICE_URL` / `RECOMMENDATION_SERVICE_URL` | `http://localhost:800{1,2,3}` | Where the Gateway and sibling services reach each other; already wired to Docker Compose service names in `docker-compose.microservices.yml` | gateway + services |
| `*_SERVICE_DATA_PATH` | per-service default under `data/` | Override a service's own JSON data file location (also used to isolate test runs) | per-service, optional |

Set them via a `.env` file in `backend/` before `docker compose up`, or directly when running a service locally:

```powershell
$env:JWT_SECRET = "a-long-random-production-secret"
uvicorn app.main:app --port 8001
```

### Frontend configuration

| Define | Default | Purpose |
|---|---|---|
| `API_BASE_URL` | `https://trip-io.duckdns.org` | Backend base URL, passed via `--dart-define`; override to `http://localhost:8000` (or `http://10.0.2.2:8000` on the Android emulator) for local dev |
| `GOOGLE_WEB_CLIENT_ID` | *(unset)* | Google OAuth web client ID for Google Sign-In, passed via `--dart-define`; required for the Google Sign-In button to work on Android/web |

## Testing

Each backend service has its own `requirements.txt`/`tests/` and is tested independently (44 tests total, covering auth, password reset, destinations/moderation, favorites, ratings, comments, itineraries incl. sharing/claiming, notifications, AI endpoints (mocked), routing (mocked), and Gateway request routing):

```powershell
cd backend/services/user_service   # or itinerary_service / recommendation_service / ../../gateway
pip install -r requirements.txt
pytest
```

**Frontend** (static analysis + widget/unit tests):

```powershell
cd frontend
flutter analyze
flutter test
```

## Containers & CI/CD

The entire backend is Docker Compose-based — see [Backend Setup](#backend-setup) for `docker compose -f docker-compose.microservices.yml up --build`. On the VPS, `backend/update_microservices.sh` pulls the latest code and redeploys the same way (`docker compose up -d --build`), with real secrets supplied via a `.env` file at the repo root (never committed).

The frontend has its own Jenkins pipeline (`frontend/jenkinsfile`) triggered on every push to `main`:

1. Builds and deploys the Windows installer from a Windows build agent (via SCP).
2. Runs `flutter analyze`/`flutter test`, then builds and deploys the Android APK and the Flutter web release directly into the Gateway's `website/downloads/` and `website/webapp/` (see [Architecture](#architecture)).

## Data Storage

Each backend service owns its own flat JSON file (`users.json`, `itineraries.json`, `destinations.json`, guarded by a `threading.Lock` for basic write safety) — no database server to provision, and no service reaches directly into another's data file. This keeps every service dependency-free and easy to run locally, at the cost of concurrency and durability guarantees suitable only for development/demo use at this scale. Cross-service reads go through small internal-only HTTP endpoints (`/internal/...`) or, for side effects, RabbitMQ events — never a shared file. `backend/scripts/migrate_data.py` is kept for historical reference (it performed the one-time split from the now-retired monolith's single `data.json`) but isn't part of the normal setup flow anymore.

## Roadmap

| Phase | Focus | Status |
|---|---|---|
| 1. Monolith | Single FastAPI service, JSON storage, working REST API | ✅ Done — retired once Phase 2 proved itself in production; code removed from the repo |
| 2. Microservices | Service decomposition, inter-service communication, API gateway | ✅ Live in production |
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
