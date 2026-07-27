"""Public, aggregated stats for the marketing website's stats page - never
exposes the Matomo API token to the browser. The website's JS calls
GET /stats/public on this backend; this module is the only thing that talks
to Matomo directly, using a token read from the environment.
"""
import logging
import os
import time

import httpx

from .data import read_data

logger = logging.getLogger("trip_io.stats")

MATOMO_URL = os.getenv("MATOMO_URL", "https://trip-io-analytics.duckdns.org")
MATOMO_API_TOKEN = os.getenv("MATOMO_API_TOKEN")
MATOMO_SITE_ID = os.getenv("MATOMO_SITE_ID", "1")

_CACHE_TTL_SECONDS = 60
_cache = {"data": None, "at": 0.0}


class MatomoApiError(Exception):
    pass


def _matomo_get(client: httpx.Client, method: str, **params) -> object:
    # Recent Matomo versions reject token_auth sent as a GET query parameter
    # (it would end up in access/proxy logs) and require it as a POST body
    # parameter instead - hence client.post(..., data=...) below, not a GET
    # with everything in the query string.
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
    # Matomo often reports auth/permission errors as HTTP 200 with an error
    # body (e.g. bad token, or a token with no access to this site) - if we
    # only checked the status code, this would silently look like "0".
    if isinstance(payload, dict) and payload.get("result") == "error":
        raise MatomoApiError(f"{method}: {payload.get('message', 'unknown error')}")
    return payload


def _unique_visitors(client: httpx.Client, period: str) -> int:
    payload = _matomo_get(
        client, "VisitsSummary.getUniqueVisitors", period=period, date="today"
    )
    # A single-period request comes back as {"value": N}, not a bare number.
    value = payload.get("value") if isinstance(payload, dict) else payload
    return int(value) if isinstance(value, (int, float)) else 0


def _daily_active(client: httpx.Client, days: int = 14) -> list[dict]:
    # period=day + a "lastN" range returns a dict keyed by date instead of a
    # single number.
    raw = _matomo_get(
        client,
        "VisitsSummary.getUniqueVisitors",
        period="day",
        date=f"last{days}",
    )
    if not isinstance(raw, dict):
        return []
    series = [
        {"date": date, "count": int(count) if isinstance(count, (int, float)) else 0}
        for date, count in raw.items()
    ]
    series.sort(key=lambda entry: entry["date"])
    return series


def _top_sections(client: httpx.Client, limit: int = 6) -> list[dict]:
    # Actions.getPageTitles reports on the `action_name` the app sends via
    # Analytics.trackScreen() for the four main tabs - this is what answers
    # "how many users visited this section this week".
    raw = _matomo_get(
        client, "Actions.getPageTitles", period="week", date="today"
    )
    if not isinstance(raw, list):
        return []
    rows = [
        {
            "name": str(row.get("label", "unknown")).strip(),
            "count": int(row.get("nb_visits") or 0),
        }
        for row in raw
    ]
    rows.sort(key=lambda row: row["count"], reverse=True)
    return rows[:limit]


def get_public_stats() -> dict:
    now = time.time()
    cached = _cache["data"]
    if cached is not None and now - _cache["at"] < _CACHE_TTL_SECONDS:
        return cached

    total_users = len(read_data().get("users", []))
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
            # Matomo unreachable/misconfigured - degrade to empty/zero rather
            # than break the public stats endpoint entirely, but log it so
            # this is actually debuggable (`journalctl -u trip_io_backend`)
            # instead of silently showing zeros with no trace of why.
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
