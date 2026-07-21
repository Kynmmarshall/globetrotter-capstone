# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions are tagged by capstone phase rather than strict SemVer — `0.x.0` tracks **Phase 1: Monolith**, `0.x` minor bumps will track **Phase 2: Microservices**, and so on, per the [course roadmap](README.md#roadmap).

## [Unreleased]

Planned for **Phase 2: Microservices** — see [README → Roadmap](README.md#roadmap).

- Decompose the monolith into independent User, Itinerary, and Recommendation services.
- Introduce an API Gateway as the single client-facing entry point.
- Replace direct in-process calls with REST (sync) and message-queue (async) inter-service communication.
- Give each service its own datastore instead of a shared JSON file.

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
