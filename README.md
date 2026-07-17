GlobeTrotter — Phase 1 (Monolith)

Minimal FastAPI monolith for Phase 1 of GlobeTrotter.

Quick start

1. Create a virtualenv and activate it.

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

2. Run the app

```powershell
uvicorn app.main:app --reload --port 8000
```

3. API docs: http://localhost:8000/docs
