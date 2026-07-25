"""Discover candidate Yaoundé destinations and nearby places from OpenStreetMap.

This is a *discovery* tool, not an auto-importer. It queries the public
Overpass API (OpenStreetMap) for points of interest and writes them to
data/destination_candidates.json for a human to read, verify against a
second source if in doubt, and manually curate into data/data.json.

Nothing here writes to data/data.json. OSM entries can be outdated, mistagged,
or missing - the project's rule is "always use real data", which means a
person checks each candidate before it becomes part of the app, the same way
every destination and nearby place already in data.json was hand-verified.

Usage:
    # Find new destination candidates across Yaoundé (museums, monuments,
    # parks, viewpoints, markets, places of worship, etc.)
    python scripts/discover_destinations.py

    # Find hotels/restaurants near a specific point, e.g. to fill in the
    # "nearby" list for one destination (coordinates from OpenStreetMap or
    # Google Maps "copy coordinates")
    python scripts/discover_destinations.py --nearby 3.8721 11.5174

Output files are written next to data/data.json:
    data/destination_candidates.json
    data/nearby_candidates.json
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

import httpx

OVERPASS_URL = "https://overpass-api.de/api/interpreter"
DATA_DIR = Path(__file__).resolve().parents[1] / "data"

# Bounding box around Yaoundé (south, west, north, east). A plain bbox is
# used instead of area["name"=...] because resolving an admin-boundary area
# is expensive on the public Overpass instance and was timing out (504).
YAOUNDE_BBOX = "3.75,11.40,3.95,11.62"

# Tag groups that map to the kind of "destination" this app curates:
# monuments/landmarks, museums, viewpoints/nature, markets, places of worship.
DESTINATION_QUERY = f"""
[out:json][timeout:60];
(
  nwr["tourism"~"^(museum|attraction|viewpoint|zoo|artwork|gallery)$"]({YAOUNDE_BBOX});
  nwr["historic"~"^(monument|memorial|castle|ruins)$"]({YAOUNDE_BBOX});
  nwr["leisure"~"^(park|nature_reserve|garden)$"]({YAOUNDE_BBOX});
  nwr["amenity"="place_of_worship"]({YAOUNDE_BBOX});
  nwr["shop"="mall"]({YAOUNDE_BBOX});
  nwr["amenity"="marketplace"]({YAOUNDE_BBOX});
  nwr["natural"="peak"]({YAOUNDE_BBOX});
);
out center;
"""

NEARBY_QUERY = """
[out:json][timeout:30];
(
  nwr["tourism"="hotel"](around:1500,{lat},{lon});
  nwr["amenity"="restaurant"](around:1500,{lat},{lon});
);
out center;
"""


_HEADERS = {
    # overpass-api.de's front end rejects requests with no/generic Accept
    # header (406), so send something explicit.
    "User-Agent": "trip_io-destination-discovery/1.0",
    "Accept": "*/*",
}


def _run_query(query: str, retries: int = 3) -> list[dict]:
    last_error: Exception | None = None
    for attempt in range(retries):
        try:
            resp = httpx.post(OVERPASS_URL, data={"data": query}, timeout=90, headers=_HEADERS)
            resp.raise_for_status()
            return resp.json().get("elements", [])
        except (httpx.HTTPStatusError, httpx.TransportError) as exc:
            last_error = exc
            print(f"  attempt {attempt + 1}/{retries} failed ({exc}); retrying...", file=sys.stderr)
            time.sleep(5)
    raise RuntimeError(f"Overpass query failed after {retries} attempts") from last_error


def _coords(el: dict) -> tuple[float, float] | None:
    if "lat" in el and "lon" in el:
        return el["lat"], el["lon"]
    center = el.get("center")
    if center:
        return center["lat"], center["lon"]
    return None


def _address(tags: dict) -> str | None:
    parts = [
        tags.get("addr:street"),
        tags.get("addr:suburb") or tags.get("addr:neighbourhood"),
        tags.get("addr:city"),
    ]
    parts = [p for p in parts if p]
    return ", ".join(parts) if parts else None


def _category(tags: dict) -> str:
    for key in ("tourism", "historic", "leisure", "amenity", "shop", "natural"):
        if key in tags:
            return f"{key}={tags[key]}"
    return "unknown"


def _normalize(el: dict) -> dict | None:
    tags = el.get("tags", {})
    name = tags.get("name") or tags.get("name:fr") or tags.get("name:en")
    if not name:
        return None
    coords = _coords(el)
    osm_url = f"https://www.openstreetmap.org/{el['type']}/{el['id']}"
    return {
        "name": name,
        "category": _category(tags),
        "address": _address(tags),
        "lat": coords[0] if coords else None,
        "lon": coords[1] if coords else None,
        "osm_url": osm_url,
        "verified": False,
        "raw_tags": tags,
    }


def _load_existing_names() -> set[str]:
    data_file = DATA_DIR / "data.json"
    if not data_file.exists():
        return set()
    data = json.loads(data_file.read_text(encoding="utf-8"))
    return {d["name"].strip().lower() for d in data.get("destinations", [])}


def discover_destinations() -> list[dict]:
    elements = _run_query(DESTINATION_QUERY)
    existing = _load_existing_names()
    candidates = []
    seen = set()
    for el in elements:
        candidate = _normalize(el)
        if not candidate:
            continue
        key = candidate["name"].strip().lower()
        if key in existing or key in seen:
            continue
        seen.add(key)
        candidates.append(candidate)
    candidates.sort(key=lambda c: c["name"])
    return candidates


def discover_nearby(lat: float, lon: float) -> list[dict]:
    elements = _run_query(NEARBY_QUERY.format(lat=lat, lon=lon))
    results = []
    seen = set()
    for el in elements:
        candidate = _normalize(el)
        if not candidate:
            continue
        key = candidate["name"].strip().lower()
        if key in seen:
            continue
        seen.add(key)
        tags = el.get("tags", {})
        candidate["place_category"] = "hotel" if tags.get("tourism") == "hotel" else "restaurant"
        results.append(candidate)
    results.sort(key=lambda c: c["name"])
    return results


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        "--nearby",
        nargs=2,
        metavar=("LAT", "LON"),
        type=float,
        help="Find hotels/restaurants near this lat/lon instead of city-wide destinations.",
    )
    args = parser.parse_args()

    DATA_DIR.mkdir(parents=True, exist_ok=True)

    if args.nearby:
        lat, lon = args.nearby
        print(f"Querying Overpass for hotels/restaurants near ({lat}, {lon})...", file=sys.stderr)
        results = discover_nearby(lat, lon)
        out_file = DATA_DIR / "nearby_candidates.json"
        out_file.write_text(json.dumps(results, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"Wrote {len(results)} candidates to {out_file}", file=sys.stderr)
    else:
        print("Querying Overpass for Yaoundé destination candidates...", file=sys.stderr)
        results = discover_destinations()
        out_file = DATA_DIR / "destination_candidates.json"
        out_file.write_text(json.dumps(results, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"Wrote {len(results)} candidates to {out_file}", file=sys.stderr)

    print("Review each entry before adding anything to data/data.json.", file=sys.stderr)


if __name__ == "__main__":
    main()
