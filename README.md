# trip_io Backend — Phase 1 (Complete)

FastAPI monolith powering **trip_io**, a travel companion for exploring, planning,
and navigating Yaoundé, Cameroon. Phase 1 covers the full feature set below:
accounts, a curated + user-submitted destination catalog with moderation,
ratings and threaded comments, favorites, auto-scheduled itineraries, an AI
assistant, turn-by-turn routing, and a web-based admin dashboard.

## Features

- **Auth** — email/password (JWT) and Google Sign-In, admin role support
- **Destinations** — search/filter a curated Yaoundé catalog (photos, tags,
  opening hours, entry fees, tips, nearby eat/stay picks, geocoordinates);
  users can submit new destinations (with a photo and a map-picked location)
  that stay hidden until an admin approves them
- **Ratings** — 1–5 star ratings, aggregated average/count per destination
- **Comments** — Reddit-style threaded comments with upvote/downvote,
  arbitrary reply depth
- **Favorites** — per-user saved destinations
- **Itineraries** — auto-scheduled single- or multi-day trip plans (title,
  destinations, generated timeline with travel buffers), owner-only delete
- **AI assistant** (Groq) — free-form chat grounded in the destination
  catalog, plus a one-tap "explain this place" per destination
- **Routing** (OpenRouteService, proxied) — turn-by-turn walking/cycling/
  driving directions through an arbitrary ordered list of waypoints, so a
  route can run from the caller's current location through every stop in an
  itinerary in order
- **Image uploads** — destination photos are stored server-side with a
  filesystem-safe filename slugified from the destination's name (matching
  the curated catalog's own naming), not the opaque destination id
- **Admin dashboard** (`website/admin.html`) — a small vanilla-JS/HTML page
  (no separate build step) for reviewing pending submissions and creating/
  editing/deleting destinations, including a click-to-set-position MapLibre
  picker and an image picker
- **Analytics** (Matomo, proxied) — page/event tracking without exposing the
  Matomo API token to the client
- **Public website** (`website/`) — landing page, download links for the
  Android APK / Web app / Windows installer, and a public stats page

## Tech stack

FastAPI + Pydantic, PyJWT, passlib/bcrypt, httpx (outbound proxy calls),
pytest/pytest-asyncio. Data is stored in a single flat JSON file
(`data/data.json`) via `app/data.py` — no database server to provision.

## Quick start

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt

uvicorn app.main:app --reload --port 8000
```

API docs (Swagger UI): http://localhost:8000/docs

## Environment variables

Every third-party integration is optional at startup - the corresponding
feature just reports "not configured" until its key is set, rather than
crashing the app.

| Variable | Purpose | Required for |
|---|---|---|
| `JWT_SECRET` | Signs auth tokens | Always (defaults to an insecure dev value) |
| `GROQ_API_KEY` | AI chat/explain | `/ai/chat`, `/ai/explain/{id}` |
| `GROQ_MODEL` | Groq model override | optional, defaults to `llama-3.3-70b-versatile` |
| `GOOGLE_OAUTH_CLIENT_ID` | Verifies Google Sign-In tokens | `/auth/google` |
| `ORS_API_KEY` | OpenRouteService directions | `/route` |
| `MATOMO_URL` / `MATOMO_API_TOKEN` / `MATOMO_SITE_ID` | Analytics proxy | `/stats/public` |
| `GLOBETROTTER_DATA_PATH` | Override the data file location | optional, defaults to `data/data.json` |

## Testing

```powershell
pytest
```

22 tests covering auth, destinations/moderation, favorites, ratings,
comments, itineraries, AI endpoints (mocked), and routing (mocked).

## Deployment

Runs as a `systemd` service on the VPS behind the public domain, with
third-party keys set via `systemctl edit` environment overrides (never
committed). The Jenkins pipeline in the companion `trip_io` repo builds and
deploys the Android APK, Flutter web app, and Windows installer, all served
from this backend's `website/` static files.
