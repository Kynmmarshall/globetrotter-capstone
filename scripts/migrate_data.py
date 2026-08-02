"""One-off migration: splits the Phase 1 monolith's data/data.json (and its
static/ uploads) into the three Phase 2 services' own data files, matching
the ownership split in gateway/app/proxy.py's routing table:

  - users               -> services/user_service/data/users.json
  - itineraries          -> services/itinerary_service/data/itineraries.json
  - destinations/ratings/comments -> services/recommendation_service/data/destinations.json

Safe to re-run: it overwrites the destination files each time rather than
appending, and never touches the original data/data.json or static/ - the
monolith keeps working off those, untouched, the whole time this migration
is being tested.

Usage (from trip_io_backend/):
    python scripts/migrate_data.py
"""
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE_DATA = ROOT / "data" / "data.json"
SOURCE_STATIC = ROOT / "static"

USER_SERVICE_DATA = ROOT / "services" / "user_service" / "data" / "users.json"
ITINERARY_SERVICE_DATA = ROOT / "services" / "itinerary_service" / "data" / "itineraries.json"
RECOMMENDATION_SERVICE_DATA = ROOT / "services" / "recommendation_service" / "data" / "destinations.json"

USER_SERVICE_AVATARS = ROOT / "services" / "user_service" / "static" / "avatars"
RECOMMENDATION_SERVICE_DESTINATIONS = ROOT / "services" / "recommendation_service" / "static" / "destinations"


def _write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"  wrote {path.relative_to(ROOT)}")


def migrate_data():
    source = json.loads(SOURCE_DATA.read_text(encoding="utf-8"))

    print("Splitting data.json ->")
    _write_json(USER_SERVICE_DATA, {"users": source.get("users", [])})
    _write_json(ITINERARY_SERVICE_DATA, {"itineraries": source.get("itineraries", [])})
    _write_json(RECOMMENDATION_SERVICE_DATA, {
        "destinations": source.get("destinations", []),
        "ratings": source.get("ratings", []),
        "comments": source.get("comments", []),
    })


def migrate_static():
    print("Copying static/ uploads ->")
    if (SOURCE_STATIC / "avatars").exists():
        shutil.copytree(SOURCE_STATIC / "avatars", USER_SERVICE_AVATARS, dirs_exist_ok=True)
        print(f"  copied static/avatars -> {USER_SERVICE_AVATARS.relative_to(ROOT)}")
    if (SOURCE_STATIC / "destinations").exists():
        shutil.copytree(SOURCE_STATIC / "destinations", RECOMMENDATION_SERVICE_DESTINATIONS, dirs_exist_ok=True)
        print(f"  copied static/destinations -> {RECOMMENDATION_SERVICE_DESTINATIONS.relative_to(ROOT)}")


def main():
    if not SOURCE_DATA.exists():
        raise SystemExit(f"Source data file not found: {SOURCE_DATA}")
    migrate_data()
    migrate_static()
    print("\nDone. The monolith's own data/ and static/ were not modified.")


if __name__ == "__main__":
    main()
