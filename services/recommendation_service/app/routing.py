"""OpenRouteService (ORS) proxy for turn-by-turn directions between
waypoints - keeps the API key server-side, same pattern as ai.py's Groq
proxy. No data.py dependency at all, so this file is identical to the
monolith's version verbatim.
"""
import logging
import os

import httpx

logger = logging.getLogger("trip_io.recommendation_service.routing")

ORS_API_KEY = os.getenv("ORS_API_KEY")
ORS_URL = "https://api.openrouteservice.org/v2/directions/{profile}/geojson"
ALLOWED_PROFILES = {"driving-car", "foot-walking", "cycling-regular"}
DEFAULT_PROFILE = "driving-car"


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

    try:
        async with httpx.AsyncClient(timeout=20) as client:
            resp = await client.post(
                ORS_URL.format(profile=profile),
                headers={"Authorization": ORS_API_KEY, "Content-Type": "application/json"},
                json={"coordinates": coordinates},
            )
        resp.raise_for_status()
        payload = resp.json()
    except httpx.HTTPError as exc:
        logger.warning("ORS request failed: %s", exc)
        raise RoutingRequestError(str(exc)) from exc

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
