"""Outbound calls this service makes to its siblings, using the
INTERNAL_SERVICE_TOKEN header (never a user JWT - these hit each service's
own /internal/* routes, which the Gateway refuses to proxy). This is the
synchronous REST inter-service communication the slide's own example
describes: Recommendation Service reading from User Service and Itinerary
Service to personalize its output.
"""
import logging
import os

import httpx

from .auth import INTERNAL_SERVICE_TOKEN

logger = logging.getLogger("trip_io.recommendation_service.clients")

USER_SERVICE_URL = os.getenv("USER_SERVICE_URL", "http://localhost:8001")
ITINERARY_SERVICE_URL = os.getenv("ITINERARY_SERVICE_URL", "http://localhost:8002")

_HEADERS = {"X-Internal-Token": INTERNAL_SERVICE_TOKEN}


async def get_user_profile(username: str) -> dict | None:
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            resp = await client.get(f"{USER_SERVICE_URL}/internal/users/{username}", headers=_HEADERS)
        if resp.status_code == 404:
            return None
        resp.raise_for_status()
        return resp.json()
    except httpx.HTTPError as exc:
        logger.warning("user_service unreachable fetching profile for %s: %s", username, exc)
        return None


async def get_user_interests(username: str) -> list[str]:
    profile = await get_user_profile(username)
    return (profile or {}).get("interests") or []


async def is_admin(username: str) -> bool:
    profile = await get_user_profile(username)
    return bool((profile or {}).get("is_admin"))


async def get_itineraries_for(username: str) -> list[dict]:
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            resp = await client.get(
                f"{ITINERARY_SERVICE_URL}/internal/itineraries/{username}", headers=_HEADERS
            )
        resp.raise_for_status()
        return resp.json()
    except httpx.HTTPError as exc:
        logger.warning("itinerary_service unreachable fetching history for %s: %s", username, exc)
        return []
