"""Outbound calls this service makes to its siblings. User Service doesn't
own destination data, so hydrating a favorites list into full Destination
objects (with ratings/comment counts) means asking recommendation_service
for them - the synchronous REST inter-service call this phase is meant to
demonstrate, in the direction the app's own domain actually needs it (not
just the slide's User->Recommendation example direction).
"""
import logging
import os

import httpx

from .auth import INTERNAL_SERVICE_TOKEN

logger = logging.getLogger("trip_io.user_service.clients")

RECOMMENDATION_SERVICE_URL = os.getenv("RECOMMENDATION_SERVICE_URL", "http://localhost:8003")
ITINERARY_SERVICE_URL = os.getenv("ITINERARY_SERVICE_URL", "http://localhost:8002")


async def get_destinations_by_ids(ids: list[str], viewer: str | None = None) -> list[dict]:
    if not ids:
        return []
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(
                f"{RECOMMENDATION_SERVICE_URL}/internal/destinations",
                params={"ids": ",".join(ids), **({"viewer": viewer} if viewer else {})},
                headers={"X-Internal-Token": INTERNAL_SERVICE_TOKEN},
            )
        resp.raise_for_status()
        return resp.json()
    except httpx.HTTPError as exc:
        logger.warning("recommendation_service unreachable while hydrating favorites: %s", exc)
        # Degrade to an empty list rather than fail the whole request - a
        # user's favorites tab going briefly empty during a sibling outage
        # beats a 502 on their own profile.
        return []


async def get_itineraries_for_user(username: str) -> list[dict]:
    """Used to compute trip-reminder notifications (see main.py) - upcoming
    itineraries aren't owned by this service, so asking itinerary_service
    is the only way to know a trip is coming up.
    """
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(
                f"{ITINERARY_SERVICE_URL}/internal/itineraries/{username}",
                headers={"X-Internal-Token": INTERNAL_SERVICE_TOKEN},
            )
        resp.raise_for_status()
        return resp.json()
    except httpx.HTTPError as exc:
        logger.warning("itinerary_service unreachable while computing trip reminders: %s", exc)
        # Degrade to no reminders rather than fail the whole notifications
        # request - a sibling outage shouldn't also hide moderation notices.
        return []
