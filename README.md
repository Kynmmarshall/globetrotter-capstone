# trip_io Backend

FastAPI microservices powering **trip_io**, a travel companion for exploring,
planning, and navigating Yaoundé, Cameroon: accounts, a curated +
user-submitted destination catalog with moderation, ratings and threaded
comments, favorites, auto-scheduled and shareable itineraries, an AI
assistant, turn-by-turn routing, in-app notifications, and a web-based admin
dashboard.

## Architecture

Four services behind a single public entry point:

- **Gateway** (`gateway/`) — the only service exposed publicly. Reverse-proxies
  each request to the right backend service (see `gateway/app/proxy.py`'s
  `ROUTES` table), serves the public website and admin dashboard
  (`website/`), and proxies analytics (`/stats/public`).
- **user_service** (`services/user_service/`) — accounts, auth (JWT +
  Google Sign-In), profile/avatar, favorites, password reset (email).
- **itinerary_service** (`services/itinerary_service/`) — itinerary CRUD,
  auto-scheduling, sharing/claiming shared trips into another account.
- **recommendation_service** (`services/recommendation_service/`) —
  destination catalog, submission moderation, ratings, comments, interest-based
  recommendations, the AI assistant (Groq), and routing (OpenRouteService).
- **RabbitMQ** — event bus between services (e.g. a new itinerary triggers a
  recommendation refresh; a moderation decision or upcoming trip triggers a
  notification), decoupling side effects from the request that caused them.

Each service owns its own data (a flat JSON file, no database server to
provision) and never reaches into another service's data file directly —
cross-service reads go through small internal-only HTTP endpoints
(`/internal/...`, blocked from public proxying at the Gateway) or, for
side effects, RabbitMQ events. This previously ran as a single-process
monolith; that's been fully retired now that this split has run the same
feature set in production.

## Features

- **Auth** — email/password (JWT) and Google Sign-In, admin role support,
  self-service password reset via a 6-digit emailed code
- **Destinations** — search/filter a curated Yaoundé catalog (photos, tags,
  opening hours, entry fees, tips, nearby eat/stay picks, geocoordinates);
  users can submit new destinations (with a photo and a map-picked location)
  that stay hidden until an admin approves them, with submission-status
  visibility and a notification on the moderation decision
- **Ratings** — 1–5 star ratings, aggregated average/count per destination
- **Comments** — Reddit-style threaded comments with upvote/downvote,
  arbitrary reply depth, edit/delete within a short window
- **Favorites** — per-user saved destinations
- **Itineraries** — auto-scheduled single- or multi-day trip plans, owner-only
  edit/delete, and shareable links: anyone who opens one gets their own copy
  added to their account (prompting account creation first if they don't
  have one)
- **Notifications** — moderation decisions on submissions and reminders for
  trips starting soon
- **AI assistant** (Groq) — free-form chat grounded in the destination
  catalog, a one-tap "explain this place" per destination, both answering in
  whichever language the app is set to
- **Routing** (OpenRouteService, proxied) — turn-by-turn walking/cycling/
  driving directions through an arbitrary ordered list of waypoints, with
  retry/backoff on transient failures
- **Image uploads** — destination photos and avatars stored server-side with
  filesystem-safe filenames
- **Admin dashboard** (`website/admin.html`) — a small vanilla-JS/HTML page
  (no separate build step) for reviewing pending submissions and creating/
  editing/deleting destinations, including a click-to-set-position MapLibre
  picker and an image picker
- **Analytics** (Matomo, proxied) — page/event tracking without exposing the
  Matomo API token to the client
- **Public website** (`website/`) — landing page, download links for the
  Android APK / Web app / Windows installer, and a public stats page

## Tech stack

FastAPI + Pydantic, PyJWT, passlib/bcrypt, httpx (inter-service + outbound
proxy calls), pika/RabbitMQ (events), pytest/pytest-asyncio.

## Quick start

```powershell
docker compose -f docker-compose.microservices.yml up --build
```

Gateway (single public entry point, website, API, `/docs` per service via
its own container): http://localhost:8000

Third-party API keys are optional at every service that reads them — the
corresponding feature just reports "not configured" until it's set, rather
than crashing the service. Set them via a `.env` file (gitignored) at the
repo root before `docker compose up`; see the table below.

## Environment variables

| Variable | Purpose | Service(s) |
|---|---|---|
| `JWT_SECRET` | Signs auth tokens | shared (defaults to an insecure dev value) |
| `INTERNAL_SERVICE_TOKEN` | Authenticates service-to-service `/internal/*` calls | shared |
| `RABBITMQ_URL` | Event bus connection | shared |
| `GOOGLE_OAUTH_CLIENT_ID` | Verifies Google Sign-In tokens | user_service |
| `SMTP_HOST` / `SMTP_PORT` / `SMTP_USER` / `SMTP_PASSWORD` / `SMTP_FROM_ADDRESS` | Password-reset email delivery | user_service |
| `PUBLIC_SITE_URL` | Base URL for the logo image in reset emails | user_service (defaults to `https://trip-io.duckdns.org`) |
| `GROQ_API_KEY` / `GROQ_MODEL` | AI chat/explain | recommendation_service |
| `ORS_API_KEY` | OpenRouteService directions | recommendation_service |
| `MATOMO_URL` / `MATOMO_API_TOKEN` / `MATOMO_SITE_ID` | Analytics proxy | gateway |
| `*_SERVICE_URL` (`USER_SERVICE_URL`, `ITINERARY_SERVICE_URL`, `RECOMMENDATION_SERVICE_URL`) | Where each service reaches its siblings | gateway + services (already wired to Docker service names in `docker-compose.microservices.yml`) |
| `*_SERVICE_DATA_PATH` | Override a service's data file location | per-service, optional |

## Testing

```powershell
cd services/user_service && pytest
cd services/itinerary_service && pytest
cd services/recommendation_service && pytest
cd gateway && pytest
```

44 tests across the four services, covering auth, password reset,
destinations/moderation, favorites, ratings, comments, itineraries
(including sharing/claiming), notifications, AI endpoints (mocked, including
language selection), routing (mocked), and Gateway request routing.

## Deployment

Runs on the VPS via `docker compose -f docker-compose.microservices.yml up
-d --build`, behind the public domain, with third-party keys set in a `.env`
file at the repo root (never committed). The Jenkins pipeline in the
companion `trip_io` repo builds and deploys the Android APK, Flutter web
app, and Windows installer, all served from the Gateway's `website/` static
files.
