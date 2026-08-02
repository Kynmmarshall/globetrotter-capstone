"""Path-based reverse proxy to the three backend services. External paths
are kept byte-for-byte identical to the old monolith's, so the Flutter app
(and the website JS) need zero changes beyond pointing API_BASE_URL at this
Gateway instead of the monolith - only this routing table needs to know
that trip_io's app-level 3-service split doesn't cleanly align with a
generic 3-service template: destinations/ratings/comments/AI/routing/admin
all live in Recommendation Service, not just "recommendations".
"""
import logging
import os

import httpx
from fastapi import Request, Response
from fastapi.responses import JSONResponse

logger = logging.getLogger("trip_io.gateway.proxy")

USER_SERVICE_URL = os.getenv("USER_SERVICE_URL", "http://localhost:8001")
ITINERARY_SERVICE_URL = os.getenv("ITINERARY_SERVICE_URL", "http://localhost:8002")
RECOMMENDATION_SERVICE_URL = os.getenv("RECOMMENDATION_SERVICE_URL", "http://localhost:8003")

# Ordered, most-specific-first - /me/submissions and /me/favorites must be
# checked before the generic /me prefix, since they route to a different
# service than plain /me, /me/interests, /me/avatar do.
ROUTES: list[tuple[str, str]] = [
    ("/me/submissions", RECOMMENDATION_SERVICE_URL),
    ("/me/favorites", USER_SERVICE_URL),
    ("/me", USER_SERVICE_URL),
    ("/register", USER_SERVICE_URL),
    ("/login", USER_SERVICE_URL),
    ("/auth/google", USER_SERVICE_URL),
    ("/static/avatars", USER_SERVICE_URL),
    ("/itineraries", ITINERARY_SERVICE_URL),
    ("/destinations", RECOMMENDATION_SERVICE_URL),
    ("/admin/destinations", RECOMMENDATION_SERVICE_URL),
    ("/comments", RECOMMENDATION_SERVICE_URL),
    ("/recommendations", RECOMMENDATION_SERVICE_URL),
    ("/ai", RECOMMENDATION_SERVICE_URL),
    ("/route", RECOMMENDATION_SERVICE_URL),
    ("/static/destinations", RECOMMENDATION_SERVICE_URL),
]

# Never proxied under any circumstances - service-to-service only, gated by
# INTERNAL_SERVICE_TOKEN, which the public Gateway never holds a reason to
# forward.
_BLOCKED_PREFIXES = ("/internal",)

# Headers that must not be forwarded as-is: `host` would point requests at
# the wrong virtual host on the target service, and the two length/encoding
# headers get recomputed by httpx/Starlette from the actual body being sent.
_HOP_BY_HOP = {"host", "content-length", "transfer-encoding", "connection"}


def resolve_target(path: str) -> str | None:
    for prefix, base_url in ROUTES:
        if path == prefix or path.startswith(prefix + "/"):
            return base_url
    return None


async def proxy_request(request: Request, full_path: str) -> Response:
    path = f"/{full_path}"

    if any(path == p or path.startswith(p + "/") for p in _BLOCKED_PREFIXES):
        return JSONResponse({"detail": "Not found"}, status_code=404)

    target_base = resolve_target(path)
    if target_base is None:
        return JSONResponse({"detail": "Not found"}, status_code=404)

    body = await request.body()
    forward_headers = {k: v for k, v in request.headers.items() if k.lower() not in _HOP_BY_HOP}

    try:
        async with httpx.AsyncClient(timeout=30) as client:
            upstream = await client.request(
                request.method,
                f"{target_base}{path}",
                params=request.query_params,
                headers=forward_headers,
                content=body,
            )
    except httpx.HTTPError as exc:
        logger.warning("Upstream %s unreachable for %s %s: %s", target_base, request.method, path, exc)
        return JSONResponse({"detail": "Service temporarily unavailable"}, status_code=502)

    response_headers = {
        k: v for k, v in upstream.headers.items() if k.lower() not in _HOP_BY_HOP
    }
    return Response(
        content=upstream.content,
        status_code=upstream.status_code,
        headers=response_headers,
        media_type=upstream.headers.get("content-type"),
    )
