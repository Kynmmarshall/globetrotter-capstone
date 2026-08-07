"""Live nearby-amenities lookup (hospitals, pharmacies, fuel stations,
hotels, banks/ATMs, police) via the public OpenStreetMap Overpass API -
same data source already used offline by
trip_io_backend/scripts/discover_destinations.py (including its exact
YAOUNDE_BBOX), always covering that whole urban area rather than a radius
around one point - the point is to show what's reachable near any of the
app's destinations, not just whichever one happens to be focused.

Reliability is handled in two layers, because a live third-party API in a
user-facing request path turned out to fail in practice (overpass-api.de
504'd during development while a mirror answered the same query fine):

1. OVERPASS_URLS tries more than one host, in order, before giving up.
2. The last successful full result is persisted to disk (see
   _cache_file_path) and kept in memory - a background task refreshes it
   periodically, and get_amenities() always serves whatever's cached rather
   than making a live call in the request path. Hospitals/pharmacies/hotels
   are static infrastructure; a few hours (or even days) old is
   functionally identical to fresh, and it means an Overpass outage now
   means "possibly slightly stale," never "empty," except on the very
   first request the service has ever handled with no disk cache yet.

The in-memory half of this is only correct because this service runs a
single uvicorn worker (see Dockerfile - no --workers flag); if that ever
changes, each worker would keep its own copy and refresh independently -
still correct, just redundant work, not a bug.
"""
import asyncio
import json
import logging
import os
import time
from pathlib import Path

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

# How often the background task tries to refresh the persisted result -
# deliberately hours, not minutes: this data barely changes day to day, and
# the whole point is to stop depending on Overpass being reachable at the
# moment a user opens the map.
BACKGROUND_REFRESH_INTERVAL_SECONDS = 6 * 60 * 60

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
    retries. Internal to this module - get_amenities() never raises this;
    it degrades to whatever's cached (see module docstring)."""


# The authoritative "last known good" result, all categories, in memory.
# None means "never successfully fetched or loaded from disk this run."
_all_amenities: list[dict] | None = None
_background_task: asyncio.Task | None = None


def _cache_file_path() -> Path:
    env_path = os.getenv("AMENITIES_CACHE_PATH")
    if env_path:
        return Path(env_path)
    return Path(__file__).resolve().parents[1] / "data" / "amenities_cache.json"


def _read_disk_cache() -> list[dict] | None:
    path = _cache_file_path()
    if not path.exists():
        return None
    try:
        with open(path, encoding="utf-8") as f:
            payload = json.load(f)
        return payload.get("results")
    except (OSError, ValueError) as exc:
        logger.warning("Could not read amenities disk cache at %s: %s", path, exc)
        return None


def _write_disk_cache(results: list[dict]) -> None:
    path = _cache_file_path()
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            json.dump({"fetched_at": time.time(), "results": results}, f, indent=2, ensure_ascii=False)
    except OSError as exc:
        logger.warning("Could not write amenities disk cache at %s: %s", path, exc)


def _build_query() -> str:
    bbox = ",".join(str(v) for v in YAOUNDE_BBOX)
    clauses = "\n".join(f"  {tag}({bbox});" for tag in CATEGORY_TAGS.values())
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


async def _refresh_all() -> bool:
    """Fetches every category fresh from Overpass and, on success, updates
    both the in-memory and disk caches. Never raises - a failure just
    leaves whatever was cached before untouched. Returns whether it
    succeeded, purely for logging/tests."""
    global _all_amenities
    try:
        elements = await _request_with_retries(_build_query())
    except AmenitiesRequestError as exc:
        logger.warning("Amenities refresh failed, keeping last known data: %s", exc)
        return False
    _all_amenities = [n for n in (_normalize(el) for el in elements) if n is not None]
    _write_disk_cache(_all_amenities)
    return True


async def get_amenities(categories: list[str]) -> list[dict]:
    global _all_amenities
    if _all_amenities is None:
        _all_amenities = _read_disk_cache()
    if _all_amenities is None:
        # Cold start with no disk cache at all (e.g. first deploy ever, or
        # the background task hasn't completed its first pass yet) - one
        # inline attempt as a last resort so this doesn't just stay empty
        # forever. _refresh_all() degrades silently, and _all_amenities
        # simply stays None if this also fails.
        await _refresh_all()
    if _all_amenities is None:
        return []
    return [a for a in _all_amenities if a["category"] in categories]


async def _refresh_loop() -> None:
    while True:
        await _refresh_all()
        await asyncio.sleep(BACKGROUND_REFRESH_INTERVAL_SECONDS)


def start_background_refresh() -> None:
    """Called once from main.py's startup hook. Immediately attempts a
    refresh (so a stale disk cache from a previous deploy gets updated
    right away rather than waiting a full interval), then repeats on
    BACKGROUND_REFRESH_INTERVAL_SECONDS."""
    global _background_task
    if _background_task is not None:
        return
    _background_task = asyncio.create_task(_refresh_loop())


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
