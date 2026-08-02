import os
from pathlib import Path

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

from . import stats
from .proxy import proxy_request

app = FastAPI(title="trip_io API Gateway")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Repo layout: gateway/app/main.py -> parents[2] is trip_io_backend/, same
# as where website/ has always lived - the public site/admin dashboard/
# webapp download page aren't part of any one service's domain, so they're
# served straight from the Gateway instead. Overridable because that
# parents[2] resolution only holds for local dev - inside the Docker image
# (WORKDIR /srv) it needs to point at a bind-mounted volume instead (see
# docker-compose.yml), since website/ holds deploy artifacts that change
# independently of a gateway image rebuild.
_website_dir = Path(os.getenv("WEBSITE_DIR") or Path(__file__).resolve().parents[2] / "website")
_downloads_dir = _website_dir / "downloads"
_webapp_dir = _website_dir / "webapp"
_downloads_dir.mkdir(parents=True, exist_ok=True)
_webapp_dir.mkdir(parents=True, exist_ok=True)

# Registered before the catch-all proxy route below, so Starlette matches
# these specific prefixes first - only requests that fall through neither
# mount reach the catch-all's own website-root fallback.
app.mount("/downloads", StaticFiles(directory=_downloads_dir), name="downloads")
app.mount("/app", StaticFiles(directory=_webapp_dir, html=True), name="webapp")


@app.get("/health")
def health():
    return {"status": "ok", "service": "gateway"}


@app.get("/stats/public")
async def public_stats():
    return await stats.get_public_stats()


def _serve_website_file(full_path: str) -> Response:
    """Hand-rolled equivalent of StaticFiles(html=True) mounted at "/" -
    can't actually use a root Mount here, since Starlette would match it
    (or the catch-all route below) for literally every path and there's no
    way to make a Mount "fall through" to a sibling route once its prefix
    matches. Doing this by hand inside the one catch-all route sidesteps
    that ordering conflict entirely.
    """
    candidate = _website_dir / full_path if full_path else _website_dir / "index.html"
    if candidate.is_dir():
        candidate = candidate / "index.html"
    try:
        candidate.resolve().relative_to(_website_dir.resolve())
    except ValueError:
        return JSONResponse({"detail": "Not found"}, status_code=404)
    if not candidate.is_file():
        return JSONResponse({"detail": "Not found"}, status_code=404)
    return FileResponse(candidate)


@app.api_route(
    "/{full_path:path}",
    methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
)
async def gateway_catch_all(request: Request, full_path: str):
    from .proxy import resolve_target

    if resolve_target(f"/{full_path}") is not None:
        return await proxy_request(request, full_path)

    if request.method != "GET":
        return JSONResponse({"detail": "Not found"}, status_code=404)
    return _serve_website_file(full_path)
