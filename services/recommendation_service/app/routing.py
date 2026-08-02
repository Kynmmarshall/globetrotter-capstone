"""OpenRouteService (ORS) proxy for turn-by-turn directions between
waypoints - keeps the API key server-side, same pattern as ai.py's Groq
proxy. No data.py dependency at all, so this file is identical to the
monolith's version verbatim.
"""
import asyncio
import logging
import os

import httpx

logger = logging.getLogger("trip_io.recommendation_service.routing")

ORS_API_KEY = os.getenv("ORS_API_KEY")
ORS_URL = "https://api.openrouteservice.org/v2/directions/{profile}/geojson"
ALLOWED_PROFILES = {"driving-car", "foot-walking", "cycling-regular"}
DEFAULT_PROFILE = "driving-car"

# ORS's free tier is rate-limited (and occasionally has transient network
# blips) - a couple of quick retries on retryable statuses smooths those
# over so the user doesn't see a failure for something that succeeds a
# second later, without retrying on errors a retry can't fix (bad request,
# no route found, etc).
_RETRYABLE_STATUSES = {429, 500, 502, 503, 504}
_RETRY_DELAYS = (0.5, 1.5)


class RoutingNotConfiguredError(Exception):
    pass


class RoutingRequestError(Exception):
    pass


async def get_route(waypoints: list[tuple[float, float]], profile: str = DEFAULT_PROFILE) -> dict:
    if not ORS_API_KEY:
        raise RoutingNotConfiguredError("ORS_API_KEY is not set")
    if len(waypoints) < 2:
        raise RoutingRequestError("At least two waypoints are required")
    if profile not in ALLOWED_PROFILES:
        profile = DEFAULT_PROFILE

    coordinates = [[lon, lat] for lat, lon in waypoints]
    payload = await _request_with_retries(profile, coordinates)

    try:
        feature = payload["features"][0]
        coords = feature["geometry"]["coordinates"]
        summary = feature["properties"]["summary"]
        return {
            "geometry": [{"lat": lat, "lon": lon} for lon, lat in coords],
            "distance_meters": summary["distance"],
            "duration_seconds": summary["duration"],
        }
    except (KeyError, IndexError, TypeError) as exc:
        logger.warning("Unexpected ORS response shape: %s", payload)
        raise RoutingRequestError("Unexpected response from routing service") from exc


async def _request_with_retries(profile: str, coordinates: list[list[float]]) -> dict:
    last_error: Exception | None = None
    for delay in (*_RETRY_DELAYS, None):
        try:
            async with httpx.AsyncClient(timeout=20) as client:
                resp = await client.post(
                    ORS_URL.format(profile=profile),
                    headers={"Authorization": ORS_API_KEY, "Content-Type": "application/json"},
                    json={"coordinates": coordinates},
                )
        except httpx.HTTPError as exc:
            # Network-level failure (timeout, connection refused, ...) -
            # always transient, always worth a retry.
            last_error = exc
            if delay is None:
                break
            logger.warning("ORS request failed (%s), retrying in %.1fs", exc, delay)
            await asyncio.sleep(delay)
            continue

        if resp.status_code < 400:
            return resp.json()

        last_error = RoutingRequestError(f"ORS returned status {resp.status_code}")
        if resp.status_code not in _RETRYABLE_STATUSES or delay is None:
            # A non-retryable status (bad request, no route found, ...)
            # fails immediately instead of burning through every retry slot
            # on an error a retry can't fix.
            break
        logger.warning("ORS returned %s, retrying in %.1fs", resp.status_code, delay)
        await asyncio.sleep(delay)

    logger.warning("ORS request failed after retries: %s", last_error)
    raise RoutingRequestError(str(last_error) if last_error else "Routing service returned an error")
