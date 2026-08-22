# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions are tagged by capstone phase rather than strict SemVer — `0.x.0` tracks **Phase 1: Monolith**, `0.x` minor bumps will track **Phase 2: Microservices**, and so on, per the [course roadmap](README.md#roadmap).

## [Unreleased]

Planned for **Phase 3: Cloud Deployment** — see [README → Roadmap](README.md#roadmap).

- Deploy the Phase 2 microservices stack to a cloud provider instead of a single VPS.
- Container orchestration (Kubernetes or Docker Swarm) in place of a single `docker compose` host.
- Load balancing and auto-scaling across multiple instances of each service.
- Cut the live deployment over from the Phase 1 monolith to the Phase 2 microservices stack.

## [0.30.0] - 2026-08-22 — In-app "What's New", itinerary flow fixes & website polish

- Added an in-app "What's New" sheet (`frontend/lib/widgets/whats_new_sheet.dart`): a hand-curated, per-version bullet list shown once after an update, tracked via `SessionController.lastSeenVersion` — the same idea as this changelog, surfaced directly to users instead of only living in the repo.
- Itinerary creation moved to its own dedicated screen (`frontend/lib/screens/create_itinerary_page.dart`) instead of an inline flow, fixing several rough edges in the process; added a `formatDuration` utility for itinerary-related screens.
- Further animated the splash screen (particle effects, animated background) and converted it to a stateful widget so its logo/spinner can animate.
- Added a "visit our website" link with localized copy on the auth screen, and fixed several website image issues (wrong filenames, broken references).
- Numerous smaller UX refinements across destinations, favorites, recommendations, notifications, and submissions screens, plus a round of French localization cleanup for consistency.

## [0.29.0] - 2026-08-18 — Tia gets a name, and stops overflowing her own context

- Meet **Tia** (Trip Intelligence Assistant) — the AI assistant's system prompt was refined and given an actual name/persona, referenced consistently in-app ("Ask Tia") instead of "the AI assistant."
- Fixed `/ai/chat` silently failing (or erroring) once the destination catalog grew past what fits comfortably in a single Groq request: the embedded catalog is now capped at the top 25 most-relevant destinations (ranked, not just truncated arbitrarily) with an overflow count noted, instead of dumping the entire 60+-destination catalog into every system prompt.

## [0.28.0] - 2026-08-15 to 2026-08-20 — Tia talks back

- The AI chat now auto-speaks its replies aloud by default (with a mute/unmute toggle in the chat sheet, and the setting persisted per device via `SessionController`) — voice input (0.27.0) is now matched with voice output.
- Improved the read-aloud voice itself: emoji are stripped before speaking (so replies don't get read as "grinning face" etc.), and a female voice is preferred when the platform's TTS engine exposes one (Android/iOS/web only — best-effort elsewhere).
- Added a subtle animation to the marketing website's landing page.

## [0.27.0] - 2026-08-12 to 2026-08-13 — Voice input for AI chat & dashboard polish

- Added `POST /ai/voice`: uploads a recorded voice message and transcribes it via Groq's Whisper (`whisper-large-v3-turbo` — ~3x cheaper/faster than plain Whisper-large-v3, and accuracy isn't the bottleneck for a short chat message). The transcript lands back in the chat's text input for the user to review and send, rather than being treated as a message on its own.
- Added a microphone button to the AI chat sheet (`frontend/lib/services/voice_launcher.dart`) that records audio client-side (via the `record` package, with its own permission handling — mirroring how the map already handles location permissions) and uploads it to `/ai/voice`. Works on mobile, Windows, and web (the browser keeps the recording in memory as a Blob rather than writing to disk).
- Dashboard tab switches now crossfade with a slight upward slide instead of swapping instantly, and cleaned up unused Linux/macOS/Windows plugin registrations left over from now-removed dependencies.

## [0.26.0] - 2026-08-10 — Tappable AI destination links & video embedding

- The AI assistant now writes destination mentions as `[[Name|id]]` links (per an updated system prompt instructing it to do so), rendered in-app as tappable links that navigate straight to that destination's detail page — plus clearer error messaging when navigation fails. Also tightened the assistant's general response-formatting instructions for more consistent, readable replies.
- Added web video embedding (`frontend/lib/services/video_embed.dart`) for destination `video_url`s: YouTube and Facebook embed directly via iframe `src`; TikTok uses its documented `blockquote` + `embed.js` integration loaded via `srcdoc` (embedding its `/embed/v2/{id}` URL directly intermittently trips TikTok's anti-abuse response). Anything else falls back to opening externally, since raw Instagram post URLs and similar block third-party framing outright.
- Improved the in-app video player's layout for portrait-orientation videos, and added a custom loading splash screen for the Flutter **web** build specifically (shown while the web engine itself boots, separate from the in-app onboarding splash).

## [0.25.0] - 2026-08-09 — Yango rides, destination videos & admin fixes

- **Yango taxi integration**: a button on the map opens a pre-filled Yango ride-order page (pickup → destination coordinates) in the browser/app, so users can request a ride to a destination in one tap.
- **Destination videos**: destinations gained a `video_url` field (admin-editable), with an in-app video player (mobile: WebView; web: embedded iframe, see 0.26.0).
- **Admin dashboard fixes**: added destination search to the admin panel, and fixed partial destination updates so an admin can now explicitly clear a field to null instead of every `PATCH` accidentally leaving untouched fields alone only by coincidence of what was sent.
- Made the destinations search bar reactive to typing (live filtering) instead of requiring a submit action.

## [0.24.0] - 2026-08-08 — Website gallery/hero image curation

- Briefly made the marketing website's hero slideshow and gallery load images dynamically from the API, then reverted both to a curated, hand-picked image list — dynamic loading pulled in inconsistent-quality/unrelated shots, whereas a curated set keeps the landing page's first impression consistent.

## [0.23.0] - 2026-08-07 — Live nearby amenities

- Added `GET /amenities` (recommendation_service): live lookup of nearby hospitals, pharmacies, fuel stations, hotels, banks/ATMs, and police stations across the whole Yaoundé urban area, sourced from the public OpenStreetMap Overpass API (no API key needed).
- Reliability is handled in two layers: multiple Overpass hosts are tried in order before giving up, and the last successful result is cached to disk and refreshed periodically in the background — requests are always served from cache rather than making a live call inline, so an Overpass outage degrades to "possibly slightly stale," never "empty."
- Displayed on the map with localized category labels and icons.
- Expanded the Yaoundé bounding box for wider coverage, raised the result cap, and optimized fetching to reduce redundant network calls.

## [0.22.0] - 2026-08-05 to 2026-08-06 — Price tiers, per-leg directions & marketing QR page

- Added a `price_tier` field to destinations (admin-editable), surfaced in the app via a `PriceTierTag` widget.
- `/route` now returns a per-leg breakdown (`legs`), not just one combined total — e.g. current-position → stop A and stop A → stop B are reported separately, so the app can show distance/duration for each hop of a multi-stop trip.
- Added `InterestTagPicker`, a shared, scrollable widget for consistent interest-tag selection across every screen that needed one, and added a `fitness` interest tag.
- Added a printable/downloadable QR code page to the marketing website (`website/qr.html`) linking to the app, for offline promotion (flyers, posters).
- Added several new restaurants, nightclubs, and hotels to the destination catalog.

## [0.21.0] - 2026-08-04 — Language-aware AI & the monolith's retirement

- The AI assistant (`/ai/chat`, `/ai/explain/{id}`) now takes an explicit `language_code`, answering strictly in English or French when the app's language is set, instead of only inferring the reply language from what the user typed.
- **The Phase 1 monolith (`backend/app/`) has been fully removed.** The Phase 2 microservices stack — Gateway + User/Itinerary/Recommendation services + RabbitMQ — now runs the entire live deployment; the monolith's code, Dockerfile, and `docker-compose.yml` are deleted from the repo rather than kept as unused dead weight. See [README → Architecture](README.md#architecture) and [→ Roadmap](README.md#roadmap).

## [0.20.0] - 2026-08-03 — Maps, directions & smarter recommendations

- Added retry-with-backoff to Recommendation Service's OpenRouteService calls: transient failures (timeouts, 5xx) get a couple of quick retries before giving up, while non-retryable errors (e.g. a bad request) fail immediately instead of burning through retry attempts pointlessly. Added matching error handling and tests for the routing service.
- Added a "Directions" button and a comment-count button directly on destination cards, plus an "approximate location" message and clearer handling of denied/unavailable location settings on the map.
- `GET /recommendations` now excludes destinations already in one of the user's itineraries (fetched via the existing Itinerary Service sync call), so recommendations don't keep re-suggesting places you've already planned to visit.
- Destinations are now marked as "read" (clearing their new-comments badge) as soon as their card is tapped, not only after opening the comments sheet.

## [0.19.0] - 2026-08-03 — Theming, onboarding & UI system refresh

- Added light/dark/system theme selection, localized in English and French.
- Introduced a `GlassPanel` widget and adopted it across screens for a consistent frosted-glass look, replacing ad hoc styling.
- Added a one-time, swipeable onboarding walkthrough shown the first time a device reaches the dashboard, and a splash screen on launch.
- Added an in-app avatar cropper (`frontend/lib/screens/avatar_cropper_page.dart`) to reposition/zoom a photo before upload — built by hand on `InteractiveViewer` rather than a crop plugin, since the app also targets Windows desktop and most Flutter cropping packages are mobile/web-only.

## [0.18.0] - 2026-08-03 — Notifications

- Added `GET /me/notifications` and `POST /me/notifications/{id}/read`, combining two sources: persisted moderation notifications and computed trip-start reminders (for itineraries starting within the next 3 days).
- Moderation notifications are the event bus's first real consumer with a side effect (previously it only logged): when an admin approves/rejects a submitted destination, `recommendation_service` publishes `destination.approved`/`destination.rejected`, and `user_service`'s event consumer turns that into a persisted notification for the submitter.
- Notification copy is never hard-coded server-side — each notification carries a Flutter ARB `title_key`/`body_key` plus `body_args`, rendered and localized entirely client-side, so English and French stay in sync automatically.
- Added a notifications screen in the app.

## [0.17.0] - 2026-08-03 — Password reset & itinerary sharing

- **Forgot password**: `POST /auth/request-password-reset` + `POST /auth/reset-password`, a two-step, code-based reset flow. The reset code is emailed via SMTP (`user_service/app/email_util.py`) with a branded HTML email (falling back to logging the code if SMTP isn't configured, so the flow stays testable without real email infrastructure) and expires after 30 minutes. The request endpoint always returns the same response regardless of whether the identifier matched an account, to avoid leaking which usernames/emails are registered.
- **Itinerary sharing**: `POST`/`DELETE /itineraries/{id}/share` mints/revokes a share token; `GET /shared/itineraries/{token}` is a public, unauthenticated endpoint returning a trimmed, viewer-safe representation of the itinerary (no ratings/favorites) for a shareable web page anyone can open, even without a trip_io account. `POST /itineraries/claim/{token}` lets a signed-in user copy a shared itinerary into their own account.
- Added clipboard-based share links and a claim-shared-itinerary flow to the app, with web support for opening a shared link directly.
- Added `SMTP_HOST`/`SMTP_PORT`/`SMTP_USER`/`SMTP_PASSWORD`/`SMTP_FROM_ADDRESS`/`PUBLIC_SITE_URL` to the microservices Docker Compose stack.

## [0.16.0] - 2026-08-02 — Itinerary editing & comment moderation

- Added `PATCH /itineraries/{id}` to edit an existing itinerary's title, destinations, schedule, or dates (ownership-checked), publishing an `itinerary.updated` event.
- Added `PATCH`/`DELETE /comments/{id}` so users can edit or delete their own comments — both restricted to a 5-minute window after posting, and deletion is refused if the comment already has replies (to avoid orphaning a reply thread).

## [0.15.0] - 2026-08-02 — Phase 2: Microservices decomposition

Decomposes the Phase 1 monolith into three independent services behind an API Gateway, satisfying every item that was previously listed under Unreleased for this phase. The monolith (`backend/app/`) is left untouched and still serves the live production deployment — this is a separate, parallel stack (`backend/docker-compose.microservices.yml`) that hasn't been cut over yet.

- **API Gateway** (`backend/gateway/`): the single public entry point (port 8000). Reverse-proxies each request to the owning service by path (`backend/gateway/app/proxy.py`), keeping every external URL byte-for-byte identical to the monolith's so the Flutter app and website only need `API_BASE_URL` repointed. Also serves the marketing site, `/downloads`, `/app`, and `/stats/public` directly, since none of those cleanly belong to one service.
- **User Service** (port 8001, internal-only): registration/login, Google Sign-In, profile, interests, avatar upload, and favorites (hydrated by calling Recommendation Service internally for the destination details).
- **Itinerary Service** (port 8002, internal-only): itinerary create/list/delete, ownership-checked.
- **Recommendation Service** (port 8003, internal-only): destinations, ratings, comments, favorites lookups, the AI assistant, routing, and admin moderation — everything that didn't cleanly split three ways landed here, since it's the natural reader of both other services' data.
- **Synchronous inter-service communication**: Recommendation Service calls User Service and Itinerary Service over internal REST endpoints (`/internal/...`), authenticated with a shared `X-Internal-Token` header (`INTERNAL_SERVICE_TOKEN`) rather than a user's JWT. These `/internal/*` routes are explicitly blocked at the Gateway and unreachable from the public internet.
- **Asynchronous inter-service communication**: a RabbitMQ topic exchange (`trip_io.events`) carries fire-and-forget domain events (`user.registered`, `itinerary.created`, `destination.rated`), published by the service that owns the action and consumed by Recommendation Service in a background thread. Publishing is best-effort — RabbitMQ being briefly down never fails the request that triggered the event.
- **Per-service datastores**: each service now owns its own JSON data file (`users.json`, `itineraries.json`, `destinations.json`) instead of one shared `data.json` — still file-based, not a proper database, but the data ownership split the roadmap called for. `backend/scripts/migrate_data.py` does a one-off, non-destructive split of the monolith's existing `data.json`/`static/` into the three services' own data/static directories.
- Added `backend/docker-compose.microservices.yml` (Gateway + 3 services + RabbitMQ) and `backend/update_microservices.sh`, a separate pull-and-redeploy script from the monolith's, so the two stacks can be tested and cut over independently.
- Fixed the public stats endpoint's total-user count silently falling back to 0 (it now fetches the real count from User Service's `GET /internal/users/count`) and fixed the microservices Compose stack publishing service ports 8001-8003 to the host, leaving only the Gateway's 8000 public.

## [0.14.0] - 2026-08-01 — AI chat suggestions, new-comments badge & read-aloud

- Added preset/suggested prompts to the AI chat sheet so users can start a conversation with one tap instead of typing from scratch; also fixed the map failing to render inside the chat flow.
- Added a "new comments" badge on destination cards and the detail page: each device locally tracks the last-seen comment count per destination (`SessionController.lastSeenCommentCount`) and shows a pill when the server-reported `comment_count` has grown since. `Destination` now reports `comment_count`.
- Added read-aloud support (`flutter_tts`) on the destination detail page — a tooltip-labelled button reads the description or AI explanation aloud, tracking which source is currently speaking so only one plays at a time.

## [0.13.0] - 2026-07-31 — Interactive maps & turn-by-turn routing

- Added `POST /route` (`backend/app/routing.py`), a server-side proxy to OpenRouteService for turn-by-turn directions between waypoints (`driving-car`, `foot-walking`, or `cycling-regular`), keeping the ORS API key off the client — same pattern already used for the Groq and Matomo integrations.
- `Destination` (and the submit/admin-update payloads) gained `lat`/`lon` coordinates.
- Added an in-app interactive map (`frontend/lib/screens/map_page.dart`) with platform-appropriate rendering (`trip_map_flutter_map.dart` / `trip_map_maplibre.dart` behind a shared `trip_map.dart` interface), a "View on map" button and map navigation from the destination detail page, and a "show my location" control backed by `geolocator` (with the necessary location permissions).
- Added a location picker (`frontend/lib/screens/location_picker_page.dart`) used both when a user submits a new destination and when an admin edits one's coordinates from the moderation panel.

## [0.12.0] - 2026-07-31 — Community destination submissions, ratings & admin moderation

- **Star ratings**: users can rate any destination 1-5 stars (`PUT`/`DELETE /destinations/{id}/rating`); the aggregated average and count are computed from the raw ratings store (never cached on the destination record, so they can't drift), and every destination response includes the viewer's own rating alongside them. Added a `StarRating` widget in the app.
- **User-submitted destinations**: `POST /destinations/submit` lets users propose a new destination (name, description, location, tags, opening hours, entry fee, tips); submissions enter a `pending` moderation queue and stay visible to their submitter via `GET /me/submissions` even if later rejected (rejected destinations are kept, not deleted). Added a dedicated submission screen (`frontend/lib/screens/submit_destination_page.dart`).
- **Destination photos**: `POST /destinations/{id}/image` lets a submitter (or an admin) attach/replace a destination's photo, restricted by ownership check.
- **Admin dashboard**: a new role-gated (`role="admin"` in `data.json`) review panel on the marketing site (`website/admin.html`, `website/admin.js`) to list destinations by status, approve/reject/edit submissions, or create/delete destinations directly — backed by `GET`/`PATCH`/`POST`/`DELETE /admin/destinations`.
- Added `GET /destinations/{id}` to fetch a single (approved) destination directly, also returning its rating summary.

## [0.11.0] - 2026-07-31 — Itinerary deletion, in-app search & UX polish

- **Itinerary deletion**: `DELETE /itineraries/{id}` (ownership-checked — only the owner can delete their own itinerary), with a confirmation dialog and snackbar feedback in the app.
- Added a search box for filtering destinations while building an itinerary, instead of scrolling the full destination list.
- Reworked comments into a draggable bottom sheet with a dedicated comments button on the dashboard; the AI assistant similarly moved into its own sheet (`widgets/ai_chat_sheet.dart`) opened via a floating action button (`widgets/ai_fab_button.dart`).
- Added an animated hero background slideshow to the marketing site's landing page.

## [0.10.0] - 2026-07-30 — Social & personalization: avatars, comments, favorites

- **Avatar upload**: `POST /me/avatar` accepts a JPEG/PNG/WEBP/GIF up to 5MB, stores it under `static/avatars/<user-id>.<ext>` (keyed by the server-generated user id, never the raw username, to avoid path-traversal risk), and replaces any previous avatar for that user.
- **Destination comments**: threaded comments per destination with replies and up/down voting — `GET`/`POST /destinations/{id}/comments` and `POST /comments/{id}/vote` — surfaced in the app via a new `CommentsSection` widget on the destination detail page, with per-viewer vote state and a 2000-character limit.
- **Favorites**: `GET /me/favorites`, `POST`/`DELETE /me/favorites/{destination_id}` let users save destinations to a personal list; added a `FavoriteToggleButton` and a dedicated favorites screen in the app, localized in English and French.
- `UserProfile` now also reports `avatar_url` and `favorite_ids`.
- Extended JWT access token lifetime from 1 hour to 1 week, so users stay signed in between sessions instead of being logged out constantly.

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
