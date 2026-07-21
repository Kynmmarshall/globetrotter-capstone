# GlobeTrotter — Travel Recommendation & Itinerary Platform

GlobeTrotter is a full-stack travel assistant that lets users search destinations, receive personalized recommendations, and build shareable travel itineraries. The repository contains two independently deployable projects:

| Project | Description | Stack |
|---|---|---|
| [`backend/`](backend/) | REST API monolith serving auth, destinations, recommendations, and itineraries | Python, FastAPI, JWT |
| [`frontend/`](frontend/) | Cross-platform client (mobile, web, desktop) | Flutter/Dart |

> **Course context:** This is the Phase 1 (Monolith) deliverable of a semester-long capstone (CS 4122) that progresses through Monolith → Microservices → Cloud Deployment → Resilience. The current architecture intentionally favors simplicity (a single API service, JSON-file storage) over scalability; later phases replace these with distributed, production-grade infrastructure.

---

## Table of Contents

- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Backend Setup](#backend-setup)
  - [Frontend Setup](#frontend-setup)
- [API Reference](#api-reference)
- [Configuration](#configuration)
- [Testing](#testing)
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
│   ├── static/               # Uploaded/served assets (e.g. destination images)
│   ├── website/              # Static marketing site + hosted web/app builds
│   ├── tests/                # Pytest + httpx API tests
│   └── requirements.txt
│
└── frontend/                 # Flutter client ("trip_io")
    ├── lib/
    │   ├── main.dart / app.dart
    │   ├── screens/           # Auth, dashboard, destinations, itineraries, profile
    │   ├── services/          # ApiClient, session controller, itinerary scheduler
    │   ├── models/            # Data models
    │   ├── themes/             # App theming
    │   └── l10n/                # Localization (English, French)
    ├── assets/
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

Clone the repository, then set up each project as described below. The backend must be running before the frontend can authenticate or fetch data.

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

Run on your platform of choice, pointing the client at the backend's base URL:

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

Base URL: `http://localhost:8000`

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/register` | — | Create a user account, returns a JWT |
| `POST` | `/login` | — | Authenticate, returns a JWT |
| `GET` | `/destinations?q=` | — | Search/list destinations by name or tag |
| `GET` | `/recommendations` | Bearer token | Get personalized destination recommendations |
| `POST` | `/itineraries` | Bearer token | Create an itinerary for the current user |
| `GET` | `/itineraries` | Bearer token | List itineraries owned by the current user |

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

Set them before starting the server, e.g.:

```powershell
$env:JWT_SECRET = "a-long-random-production-secret"
uvicorn app.main:app --port 8000
```

### Frontend configuration

| Define | Default | Purpose |
|---|---|---|
| `API_BASE_URL` | `http://localhost:8000` (web/desktop) or `http://10.0.2.2:8000` (Android) | Backend base URL, passed via `--dart-define` |

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

No license file is currently included in this repository; all rights reserved by the author unless a license is added.
