"""Outbound calls this service makes to its siblings - same pattern as
user_service/app/clients.py. Itinerary Service doesn't own destination
data, so rendering a shared itinerary's stops (name, photo, location) means
asking recommendation_service for them.
"""
import logging
import os

import httpx

from .auth import INTERNAL_SERVICE_TOKEN

logger = logging.getLogger("trip_io.itinerary_service.clients")

RECOMMENDATION_SERVICE_URL = os.getenv("RECOMMENDATION_SERVICE_URL", "http://localhost:8003")


async def get_destinations_by_ids(ids: list[str]) -> list[dict]:
    if not ids:
        return []
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(
                f"{RECOMMENDATION_SERVICE_URL}/internal/destinations",
                params={"ids": ",".join(ids)},
                headers={"X-Internal-Token": INTERNAL_SERVICE_TOKEN},
            )
        resp.raise_for_status()
        return resp.json()
    except httpx.HTTPError as exc:
        logger.warning("recommendation_service unreachable while hydrating a shared itinerary: %s", exc)
        # Degrade to an empty list rather than fail the whole request - a
        # shared itinerary showing no stop details during a sibling outage
        # beats a 502 for whoever it was shared with.
        return []
