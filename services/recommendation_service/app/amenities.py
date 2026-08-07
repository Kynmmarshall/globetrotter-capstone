"""Live nearby-amenities lookup (hospitals, pharmacies, fuel stations,
hotels, banks/ATMs, police) via the public OpenStreetMap Overpass API -
same data source already used offline by
trip_io_backend/scripts/discover_destinations.py (including its exact
YAOUNDE_BBOX), but this is the first time it's queried live inside a
running request, and it always covers that whole urban area rather than a
radius around one point - the point is to show what's reachable near any
of the app's destinations, not just whichever one happens to be focused.

That live-vs-offline distinction matters: overpass-api.de is a shared,
rate-limited public instance, fine for a one-shot curation script but not
something a live user-facing feature can depend on being fast or even up -
confirmed in practice (it 504'd during development while a public mirror
answered the same query fine), which is why OVERPASS_URLS tries more than
one host. This module treats every result as best-effort - callers should
degrade to an empty list on failure (see main.py's /amenities endpoint)
rather than surfacing an error - and an in-memory cache means the whole
city is only ever actually queried once per TTL window, not once per
request.

The in-memory cache is only correct because this service runs a single
uvicorn worker (see Dockerfile - no --workers flag); if that ever changes,
each worker would keep its own copy and the cache would quietly get less
effective, not incorrect.
"""
import asyncio
import logging
import time

import httpx

logger = logging.getLogger("trip_io.recommendation_service.amenities")

# Tried in order - overpass-api.de first (the "main" public instance), then
# a mirror if it's down/timing out. Both are free, public, no-key-needed
# instances of the same Overpass software, so a query built once works
# against either.
OVERPASS_URLS = (
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
)

# south, west, north, east - identical to discover_destinations.py's
# YAOUNDE_BBOX, so "nearby amenities" and "where the app's own curated
# destinations are" are drawn from the same understanding of "Yaoundé."
YAOUNDE_BBOX = (3.75, 11.40, 3.95, 11.62)

_RETRYABLE_STATUSES = {429, 500, 502, 503, 504}
_RETRY_DELAYS = (0.5, 1.5)
_CACHE_TTL_SECONDS = 30 * 60
# Generous but not unbounded - a bbox this size can genuinely have
# hundreds of banks/hotels/pharmacies, and per-category legend filtering
# (not a smaller result set) is how the UI keeps that from being clutter.
_RESULT_CAP = 800

# overpass-api.de (and mirrors) reject requests with no/generic Accept
# header (406) - same headers discover_destinations.py already found
# necessary.
_HEADERS = {
    "User-Agent": "trip_io-amenities/1.0",
    "Accept": "*/*",
}

# key -> OSM tag/value to match. "bank_atm" merges two separate OSM tags
# into one traveler-facing category ("where can I get cash" isn't "bank vs
# ATM" to a visitor).
CATEGORY_TAGS: dict[str, str] = {
    "hospital": 'nwr["amenity"="hospital"]',
    "pharmacy": 'nwr["amenity"="pharmacy"]',
    "fuel": 'nwr["amenity"="fuel"]',
    "hotel": 'nwr["tourism"="hotel"]',
    "bank_atm": 'nwr["amenity"~"^(bank|atm)$"]',
    "police": 'nwr["amenity"="police"]',
}
ALLOWED_CATEGORIES = set(CATEGORY_TAGS)

# category -> fallback display name when OSM has no name tag at all (still
# worth a dot on the map - an unnamed pharmacy is still a real pharmacy).
_CATEGORY_FALLBACK_NAME = {
    "hospital": "Hospital",
    "pharmacy": "Pharmacy",
    "fuel": "Fuel station",
    "hotel": "Hotel",
    "bank_atm": "Bank / ATM",
    "police": "Police station",
}


class AmenitiesRequestError(Exception):
    """Every configured Overpass host is unreachable/erroring after
    retries. Callers should degrade to an empty list rather than surface
    this - see main.py."""


# cache key -> (expires_at_monotonic, results)
_cache: dict[tuple, tuple[float, list[dict]]] = {}


def _cache_key(categories: list[str]) -> tuple:
    return tuple(sorted(categories))


def _build_query(categories: list[str]) -> str:
    bbox = ",".join(str(v) for v in YAOUNDE_BBOX)
    clauses = "\n".join(f"  {CATEGORY_TAGS[c]}({bbox});" for c in categories)
    return f"[out:json][timeout:30];\n(\n{clauses}\n);\nout center {_RESULT_CAP};"


def _coords(el: dict) -> tuple[float, float] | None:
    if "lat" in el and "lon" in el:
        return el["lat"], el["lon"]
    center = el.get("center")
    if center:
        return center["lat"], center["lon"]
    return None


def _category_for(tags: dict) -> str | None:
    amenity = tags.get("amenity")
    if amenity == "hospital":
        return "hospital"
    if amenity == "pharmacy":
        return "pharmacy"
    if amenity == "fuel":
        return "fuel"
    if amenity in ("bank", "atm"):
        return "bank_atm"
    if amenity == "police":
        return "police"
    if tags.get("tourism") == "hotel":
        return "hotel"
    return None


def _normalize(el: dict) -> dict | None:
    tags = el.get("tags", {})
    category = _category_for(tags)
    coords = _coords(el)
    if category is None or coords is None:
        return None
    name = tags.get("name") or tags.get("name:fr") or tags.get("name:en") or _CATEGORY_FALLBACK_NAME[category]
    return {
        "id": f"{el['type']}/{el['id']}",
        "name": name,
        "category": category,
        "lat": coords[0],
        "lon": coords[1],
    }


async def get_amenities(categories: list[str]) -> list[dict]:
    key = _cache_key(categories)
    cached = _cache.get(key)
    if cached and cached[0] > time.monotonic():
        return cached[1]

    query = _build_query(categories)
    elements = await _request_with_retries(query)
    results = [n for n in (_normalize(el) for el in elements) if n is not None]
    _cache[key] = (time.monotonic() + _CACHE_TTL_SECONDS, results)
    return results


async def _request_with_retries(query: str) -> list[dict]:
    last_error: Exception | None = None
    for url in OVERPASS_URLS:
        for delay in (*_RETRY_DELAYS, None):
            try:
                async with httpx.AsyncClient(timeout=25) as client:
                    resp = await client.post(url, data={"data": query}, headers=_HEADERS)
            except httpx.HTTPError as exc:
                last_error = exc
                if delay is None:
                    break
                logger.warning("Overpass request to %s failed (%s), retrying in %.1fs", url, exc, delay)
                await asyncio.sleep(delay)
                continue

            if resp.status_code < 400:
                return resp.json().get("elements", [])

            last_error = AmenitiesRequestError(f"{url} returned status {resp.status_code}")
            if resp.status_code not in _RETRYABLE_STATUSES or delay is None:
                break
            logger.warning("Overpass at %s returned %s, retrying in %.1fs", url, resp.status_code, delay)
            await asyncio.sleep(delay)
        logger.warning("Overpass host %s exhausted, trying next host if any", url)

    logger.warning("Amenities lookup failed on every Overpass host: %s", last_error)
    raise AmenitiesRequestError(str(last_error) if last_error else "Overpass request failed")
