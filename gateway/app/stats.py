"""Public, aggregated stats for the marketing website's stats page - lives
in the Gateway rather than any one of the three services since it doesn't
cleanly belong to any of them (it's a mix of Matomo data and a user count
that has to be fetched from User Service). Never exposes the Matomo API
token to the browser - the website's JS calls GET /stats/public on this
Gateway; this module is the only thing that talks to Matomo directly.
"""
import logging
import os
import time

import httpx

logger = logging.getLogger("trip_io.gateway.stats")

MATOMO_URL = os.getenv("MATOMO_URL", "https://trip-io-analytics.duckdns.org")
MATOMO_API_TOKEN = os.getenv("MATOMO_API_TOKEN")
MATOMO_SITE_ID = os.getenv("MATOMO_SITE_ID", "1")
USER_SERVICE_URL = os.getenv("USER_SERVICE_URL", "http://localhost:8001")
INTERNAL_SERVICE_TOKEN = os.getenv("INTERNAL_SERVICE_TOKEN", "dev-internal-token-change-me")

_CACHE_TTL_SECONDS = 60
_cache = {"data": None, "at": 0.0}


class MatomoApiError(Exception):
    pass


def _matomo_get(client: httpx.Client, method: str, **params) -> object:
    resp = client.post(
        f"{MATOMO_URL}/index.php",
        params={
            "module": "API",
            "method": method,
            "idSite": MATOMO_SITE_ID,
            "format": "JSON",
            **params,
        },
        data={"token_auth": MATOMO_API_TOKEN},
    )
    resp.raise_for_status()
    payload = resp.json()
    if isinstance(payload, dict) and payload.get("result") == "error":
        raise MatomoApiError(f"{method}: {payload.get('message', 'unknown error')}")
    return payload


def _unique_visitors(client: httpx.Client, period: str) -> int:
    payload = _matomo_get(client, "VisitsSummary.getUniqueVisitors", period=period, date="today")
    value = payload.get("value") if isinstance(payload, dict) else payload
    return int(value) if isinstance(value, (int, float)) else 0


def _daily_active(client: httpx.Client, days: int = 14) -> list[dict]:
    raw = _matomo_get(client, "VisitsSummary.getUniqueVisitors", period="day", date=f"last{days}")
    if not isinstance(raw, dict):
        return []
    series = [
        {"date": date, "count": int(count) if isinstance(count, (int, float)) else 0}
        for date, count in raw.items()
    ]
    series.sort(key=lambda entry: entry["date"])
    return series


def _top_sections(client: httpx.Client, limit: int = 6) -> list[dict]:
    raw = _matomo_get(client, "Actions.getPageTitles", period="week", date="today")
    if not isinstance(raw, list):
        return []
    rows = [
        {"name": str(row.get("label", "unknown")).strip(), "count": int(row.get("nb_visits") or 0)}
        for row in raw
    ]
    rows.sort(key=lambda row: row["count"], reverse=True)
    return rows[:limit]


async def _total_users() -> int:
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            resp = await client.get(
                f"{USER_SERVICE_URL}/internal/users/count",
                headers={"X-Internal-Token": INTERNAL_SERVICE_TOKEN},
            )
        resp.raise_for_status()
        return resp.json().get("count", 0)
    except httpx.HTTPError as exc:
        logger.warning("user_service unreachable fetching total_users: %s", exc)
        return 0


async def get_public_stats() -> dict:
    now = time.time()
    cached = _cache["data"]
    if cached is not None and now - _cache["at"] < _CACHE_TTL_SECONDS:
        return cached

    total_users = await _total_users()
    active_today = 0
    active_this_week = 0
    daily_active: list[dict] = []
    top_sections: list[dict] = []

    if not MATOMO_API_TOKEN:
        logger.warning("MATOMO_API_TOKEN is not set - public stats will show zeros")
    else:
        try:
            with httpx.Client(timeout=5) as client:
                active_today = _unique_visitors(client, "day")
                active_this_week = _unique_visitors(client, "week")
                daily_active = _daily_active(client)
                top_sections = _top_sections(client)
        except (httpx.HTTPError, ValueError, MatomoApiError) as exc:
            logger.warning("Matomo stats fetch failed: %s", exc)

    result = {
        "total_users": total_users,
        "active_today": active_today,
        "active_this_week": active_this_week,
        "daily_active": daily_active,
        "top_sections": top_sections,
    }
    _cache["data"] = result
    _cache["at"] = now
    return result
