"""Fetch real, freely-licensed photos for destination candidates for human review.

Reads data/destination_candidates.json (produced by discover_destinations.py
and hand-curated down to real places) and tries to find a matching photo on
Wikimedia Commons for each entry - via its Wikidata "image" claim when OSM
tagged one, otherwise via a Commons search that requires the result to
actually reference Yaoundé/Cameroon so we don't attach an unrelated photo
(e.g. a same-named place in a different country).

This does NOT touch data.json, static/, or the app in any way. It only
downloads pictures into data/candidate_images/ and writes
data/candidate_images_manifest.json describing what was found (or not) and
where each photo came from, so a human can look at the folder, delete what's
wrong, and hand-pick the rest into static/destinations/.

Usage:
    python scripts/fetch_candidate_images.py
"""

from __future__ import annotations

import json
import re
import sys
import time
import unicodedata
from pathlib import Path

import httpx

DATA_DIR = Path(__file__).resolve().parents[1] / "data"
IMAGES_DIR = DATA_DIR / "candidate_images"
MANIFEST_PATH = DATA_DIR / "candidate_images_manifest.json"

HEADERS = {"User-Agent": "trip_io-destination-discovery/1.0 (candidate photo review)"}

WIKIDATA_API = "https://www.wikidata.org/w/api.php"
COMMONS_API = "https://commons.wikimedia.org/w/api.php"

LOCATION_HINTS = ("yaound", "cameroun", "cameroon", "centre region", "cm-ce")

STOPWORDS = {
    "marche", "march", "mont", "place", "de", "du", "des", "la", "le", "les",
    "et", "d", "l", "saint", "sainte", "eglise", "mosquee", "cathedrale",
    "monument", "jardin", "parc", "parcours", "grande", "grand", "petit",
    "petite", "vieux", "aux", "au", "en",
}


def _tokens(text: str) -> set[str]:
    ascii_text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode().lower()
    words = re.findall(r"[a-z0-9]+", ascii_text)
    return {w for w in words if len(w) >= 3 and w not in STOPWORDS}


def _subject_matches(name: str, title: str) -> bool:
    name_tokens = _tokens(name)
    if not name_tokens:
        return True
    title_tokens = _tokens(title)
    return bool(name_tokens & title_tokens)


def _slug(name: str) -> str:
    ascii_name = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode()
    slug = re.sub(r"[^a-zA-Z0-9]+", "-", ascii_name).strip("-").lower()
    return slug or "unnamed"


def _get(url: str, params: dict) -> dict:
    resp = httpx.get(url, params=params, headers=HEADERS, timeout=30)
    resp.raise_for_status()
    return resp.json()


def _looks_local(text: str) -> bool:
    low = text.lower()
    return any(hint in low for hint in LOCATION_HINTS)


def _commons_file_info(title: str) -> dict | None:
    """Given a Commons File: title, return its url + a location-relevance signal."""
    data = _get(
        COMMONS_API,
        {
            "action": "query",
            "format": "json",
            "titles": title,
            "prop": "imageinfo",
            "iiprop": "url|extmetadata",
            "iiurlwidth": 1200,
        },
    )
    pages = data.get("query", {}).get("pages", {})
    for page in pages.values():
        infos = page.get("imageinfo")
        if not infos:
            continue
        info = infos[0]
        meta = info.get("extmetadata", {})
        blob = " ".join(
            str(meta.get(k, {}).get("value", ""))
            for k in ("Categories", "ImageDescription", "ObjectName")
        )
        return {
            "url": info.get("thumburl") or info.get("url"),
            "page_url": f"https://commons.wikimedia.org/wiki/{title.replace(' ', '_')}",
            "license": meta.get("LicenseShortName", {}).get("value"),
            "local_hint": _looks_local(blob) or _looks_local(title),
        }
    return None


def _from_wikidata(qid: str) -> dict | None:
    try:
        data = _get(WIKIDATA_API, {"action": "wbgetclaims", "entity": qid, "property": "P18", "format": "json"})
        claims = data.get("claims", {}).get("P18")
        if not claims:
            return None
        filename = claims[0]["mainsnak"]["datavalue"]["value"]
        return _commons_file_info(f"File:{filename}")
    except Exception:
        return None


def _from_commons_search(query: str) -> dict | None:
    try:
        data = _get(
            COMMONS_API,
            {
                "action": "query",
                "format": "json",
                "generator": "search",
                "gsrsearch": f"{query} Yaounde",
                "gsrnamespace": 6,
                "gsrlimit": 8,
                "prop": "imageinfo",
                "iiprop": "url|extmetadata",
                "iiurlwidth": 1200,
            },
        )
    except Exception:
        return None
    pages = data.get("query", {}).get("pages", {})
    for page in pages.values():
        title = page.get("title", "")
        infos = page.get("imageinfo")
        if not infos:
            continue
        info = infos[0]
        meta = info.get("extmetadata", {})
        blob = " ".join(
            str(meta.get(k, {}).get("value", ""))
            for k in ("Categories", "ImageDescription", "ObjectName")
        )
        # Require BOTH a Yaoundé/Cameroon signal AND actual word overlap
        # between the candidate's name and the file title/description -
        # location alone isn't enough (e.g. two unrelated markets in the
        # same city both turned up for each other's queries during testing).
        if (_looks_local(blob) or _looks_local(title)) and (
            _subject_matches(query, title) or _subject_matches(query, blob)
        ):
            return {
                "url": info.get("thumburl") or info.get("url"),
                "page_url": f"https://commons.wikimedia.org/wiki/{title.replace(' ', '_')}",
                "license": meta.get("LicenseShortName", {}).get("value"),
                "local_hint": True,
            }
    return None


def _download(url: str, dest: Path, retries: int = 3) -> bool:
    for attempt in range(retries):
        try:
            resp = httpx.get(url, headers=HEADERS, timeout=30, follow_redirects=True)
            if resp.status_code == 429:
                time.sleep(10)
                continue
            resp.raise_for_status()
            dest.write_bytes(resp.content)
            return True
        except Exception as exc:
            print(f"  download failed (attempt {attempt + 1}): {exc}", file=sys.stderr)
            time.sleep(3)
    return False


def main() -> None:
    candidates = json.loads((DATA_DIR / "destination_candidates.json").read_text(encoding="utf-8"))
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)

    manifest = []
    for i, cand in enumerate(candidates, 1):
        name = cand["name"]
        print(f"[{i}/{len(candidates)}] {name}", file=sys.stderr)
        qid = cand.get("extra_tags", {}).get("wikidata")
        info = None
        source = None
        if qid:
            info = _from_wikidata(qid)
            source = "wikidata" if info else None
        if not info:
            info = _from_commons_search(name)
            source = "commons_search" if info else None

        entry = {
            "name": name,
            "osm_url": cand["osm_url"],
            "found": False,
        }
        if info and info.get("url"):
            slug = _slug(name)
            ext = Path(info["url"].split("?")[0]).suffix or ".jpg"
            dest = IMAGES_DIR / f"{slug}{ext}"
            if _download(info["url"], dest):
                entry.update(
                    found=True,
                    file=str(dest.relative_to(DATA_DIR)),
                    source=source,
                    commons_page=info["page_url"],
                    license=info.get("license"),
                )
        manifest.append(entry)
        time.sleep(0.3)  # be polite to the shared API

    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    found_count = sum(1 for e in manifest if e["found"])
    print(f"\nFound photos for {found_count}/{len(manifest)} candidates.", file=sys.stderr)
    print(f"Images in {IMAGES_DIR}", file=sys.stderr)
    print(f"Manifest at {MANIFEST_PATH}", file=sys.stderr)


if __name__ == "__main__":
    main()
