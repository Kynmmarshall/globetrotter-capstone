# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions are tagged by capstone phase rather than strict SemVer — `0.x.0` tracks **Phase 1: Monolith**, `0.x` minor bumps will track **Phase 2: Microservices**, and so on, per the [course roadmap](README.md#roadmap).

## [Unreleased]

Planned for **Phase 2: Microservices** — see [README → Roadmap](README.md#roadmap).

- Decompose the monolith into independent User, Itinerary, and Recommendation services.
- Introduce an API Gateway as the single client-facing entry point.
- Replace direct in-process calls with REST (sync) and message-queue (async) inter-service communication.
- Give each service its own datastore instead of a shared JSON file.

## [0.10.0] - 2026-07-30 — Social & personalization: avatars, comments, favorites

- **Avatar upload**: `POST /me/avatar` accepts a JPEG/PNG/WEBP/GIF up to 5MB, stores it under `static/avatars/<user-id>.<ext>` (keyed by the server-generated user id, never the raw username, to avoid path-traversal risk), and replaces any previous avatar for that user.
- **Destination comments**: threaded comments per destination with replies and up/down voting — `GET`/`POST /destinations/{id}/comments` and `POST /comments/{id}/vote` — surfaced in the app via a new `CommentsSection` widget on the destination detail page, with per-viewer vote state and a 2000-character limit.
- **Favorites**: `GET /me/favorites`, `POST`/`DELETE /me/favorites/{destination_id}` let users save destinations to a personal list; added a `FavoriteToggleButton` and a dedicated favorites screen in the app, localized in English and French.
- `UserProfile` now also reports `avatar_url` and `favorite_ids`.

## [0.9.0] - 2026-07-30 — AI travel assistant

- Added an AI chat assistant (`POST /ai/chat`) and a per-destination "explain this place" endpoint (`POST /ai/explain/{destination_id}`), backed by Groq's OpenAI-compatible chat completions API (`backend/app/ai.py`). Every answer is grounded in the app's real destination catalog — the assistant is instructed never to invent places, prices, hours, or ratings that aren't in the data — and responses lean on the asking user's stored interests when relevant.
- `/ai/explain` results are cached per-destination (`Destination.ai_explanation`) so the same explanation isn't regenerated on every view.
- Added a dedicated "Ask AI" screen in the app (`frontend/lib/screens/ask_ai_page.dart`) with localized copy, and client-side chat history: the last 16 messages persist across app restarts via `SessionController`/`shared_preferences` and are cleared on logout, so the assistant isn't silently sent a user's entire lifetime chat history on every turn.
- Both AI endpoints degrade gracefully (503 if unconfigured, 502 on upstream failure) instead of crashing the request when Groq is unreachable or `GROQ_API_KEY` isn't set.

## [0.8.0] - 2026-07-30 — Google Sign-In

- Added `POST /auth/google`: verifies a Google ID token server-side against Google's `tokeninfo` endpoint (checking issuer, expiry, and that the audience matches `GOOGLE_OAUTH_CLIENT_ID`) and transparently creates or logs in the matching local account.
- Added a platform-aware Google Sign-In button to the auth screen — a native button on mobile, and Google's own rendered button on web (required there for a reliably returned ID token).
- The Jenkins pipeline now injects `GOOGLE_WEB_CLIENT_ID` via `--dart-define` into the Android and web release builds.

## [0.7.0] - 2026-07-28 — UI polish: responsive dashboard & website redesign

- Reworked the dashboard screen layout so it adapts to the available space instead of using fixed sizing.
- Refreshed the marketing website's visual design (layout, styling, copy) across the landing page and stats page.

## [0.6.0] - 2026-07-27 — Product analytics & public stats page

- Integrated [Matomo](https://matomo.org/) for product analytics: the Flutter client (`frontend/lib/services/analytics.dart`) tracks screen views and events via Matomo's HTTP Tracking API — a hand-rolled client (not the `matomo_tracker` package) so behavior is identical across mobile/Windows/web with no platform channels or extra dependency risk. Tracking never breaks the app: network/tracker failures are swallowed silently. Events are attributed to the logged-in user after login/register.
- Added a public, aggregated stats endpoint, `GET /stats/public` (`backend/app/stats.py`): total registered users (from local data), unique visitors today/this week, a 14-day daily-active series, and top visited sections — all sourced from the Matomo Reporting API server-side, with a 60s in-process cache. The Matomo API token stays server-side only; it is never exposed to the browser.
- Added a public stats page to the marketing site (`website/stats.html`, `website/stats.js`) rendering the above as charts/tables, localized in English and French alongside the rest of the now-bilingual website (`website/i18n.js`).
- Fixed Matomo rejecting `token_auth` when sent as a GET query parameter (recent Matomo versions require it as a POST body field instead) and fixed the tracker not showing data on the website; added a manual refresh control so stats update without a full page reload.

## [0.5.0] - 2026-07-25 — CI/CD pipeline

- Added a Jenkins pipeline (`frontend/jenkinsfile`) triggered on every push to `main`, spanning two agents:
  - A Windows agent builds the Windows installer (`flutter build windows` + Inno Setup) and deploys it to the VPS over SCP.
  - The VPS agent runs `flutter analyze`/`flutter test`, builds the Android APK and the Flutter web release, and deploys both directly into `website/downloads/` and `website/webapp/` on the running backend.
- Build status notifications emailed on success/failure.

## [0.4.0] - 2026-07-25 — Personalization, richer destinations & date-based itineraries

- **User interests & personalized recommendations**: `UserCreate.interests`, new `GET /me` and `PUT /me/interests` endpoints, and `recommendations_for()` now scores destinations by tag overlap with the user's interests (falling back to the first 3 destinations when a user has none set).
- **Richer destination details**: `Destination` gained `nearby` (nearby hotels/restaurants), `opening_hours`, `entry_fee`, and `tips` fields.
- **Interest-based filtering**: the destinations screen can now filter by interest tag, in both English and French; added an interest picker to onboarding/profile (`frontend/lib/models/interest_tags.dart`) kept in sync with the backend's tag vocabulary.
- **Date-based itineraries**: `Itinerary`/`ItineraryCreate` gained `start_date`/`end_date`, and the itinerary screen was updated to collect and display them.
- **Community section**: added a "Join the trip_io community" (WhatsApp) section to the marketing site.
- Added destination-discovery tooling (`backend/scripts/discover_destinations.py`, `fetch_candidate_images.py`) used to research and vet new destinations/images before adding them to the seed data, and expanded the seeded destination set.

## [0.3.0] - 2026-07-23 — Containerized deployment

- Added a backend `Dockerfile` (Python 3.11-slim + uvicorn) and a `GET /health` endpoint for container health checks.
- Added a frontend `Dockerfile` that builds the Flutter web release and serves it via Nginx (`frontend/nginx.conf`); desktop/mobile targets remain out of scope for containerization.
- Added `backend/docker-compose.yml` to run both services together for local development, as an alternative to the systemd + Nginx setup on the VPS.

## [0.2.0] - 2026-07-21 — Deployed to production VPS

- Deployed the FastAPI backend to a VPS, reachable at [https://trip-io.duckdns.org](https://trip-io.duckdns.org), serving the API, the marketing/downloads site, and the hosted Flutter web build (`/app/`) from the same host.
- Published Windows (`trip_io_windows.exe`) and Android (`trip_io.apk`) release builds via the site's downloads section.
- Updated `ApiClient._defaultBaseUrl()` (`frontend/lib/services/api_client.dart`) so the Flutter client defaults to the deployed API instead of `localhost`, falling back to `--dart-define=API_BASE_URL=...` for local development.
- Documented the live deployment URLs in the top-level [README.md](README.md).

## [0.1.0] - 2026-07-21 — Phase 1: Monolith

Initial working deliverable: a single-server REST API with a JSON file datastore, plus a cross-platform Flutter client. Satisfies the Phase 1 requirement of a working monolithic API with at least 5 endpoints.

### Added — Backend (`backend/`)

- FastAPI application (`app/main.py`) exposing the 6 required endpoints:
  - `POST /register` — create a user account and return a JWT.
  - `POST /login` — authenticate an existing user and return a JWT.
  - `GET /destinations` — search/list destinations by name or tag.
  - `GET /recommendations` — return personalized destination recommendations (authenticated).
  - `POST /itineraries` — create an itinerary for the current user (authenticated).
  - `GET /itineraries` — list itineraries owned by the current user (authenticated).
- JWT-based authentication (`app/auth.py`) using PyJWT (HS256) with a configurable `JWT_SECRET`, and PBKDF2-SHA256 password hashing via passlib.
- JSON-file data access layer (`app/data.py`, `app/crud.py`) with a thread lock for basic write safety and a configurable path via `GLOBETROTTER_DATA_PATH`.
- CORS middleware enabled for all origins to support the separately-hosted Flutter client during development.
- Static file hosting for uploaded/seed assets (`/static`), a bundled marketing site at the API root (`website/`), and mount points for a hosted web build (`/app`) and downloadable release artifacts (`/downloads`).
- Seed destination imagery for local landmarks (basilica, national museum, Mont Fébé, Mvog-Betsi Zoo, Marché Central, Palais des Congrès, Réunification Monument, Blackitude Museum).
- Pytest + httpx async test suite (`tests/test_api.py`) covering registration, login, destination search, recommendations, and itinerary create/list, isolated via a temporary data file per run.

### Added — Frontend (`frontend/`, Flutter package `trip_io`)

- Cross-platform Flutter client targeting Web, Android, iOS, Windows, macOS, and Linux.
- Screens for authentication, dashboard, destination browsing and detail view, itinerary listing and detail view, recommendations, and user profile.
- `ApiClient` service wrapping all backend endpoints (register, login, destinations, recommendations, itinerary create/list) with JWT bearer-token handling and error surfacing from API error responses.
- `SessionController` for auth/session state and `ItineraryScheduler` for itinerary date/time scheduling logic.
- Adaptive layout: bottom navigation on phones, navigation rail on tablet/desktop/web/Windows.
- Runtime-configurable backend URL — via `--dart-define=API_BASE_URL=...` at launch or directly from the login screen — with sensible per-platform defaults (`localhost` for web/desktop, `10.0.2.2` for the Android emulator).
- Localization support for English and French (`lib/l10n`).
- App theming and launcher icon generation configured for all target platforms (`flutter_launcher_icons`).

### Added — Repository

- Top-level [README.md](README.md) documenting architecture, setup, API reference, and configuration for both projects.
- Per-project quick-start READMEs in `backend/` and `frontend/`.
