"""
app/models.py

Data models and file I/O helpers.

All persistent data is stored in JSON files under the /data directory.
  - data/users.json       – registered users
  - data/itineraries.json – user itineraries
  - data/destinations.json – static destination catalogue (seed data)
"""
import json
import os

# Resolve the /data directory relative to this file's location so the app
# works regardless of the current working directory.
_BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(_BASE_DIR, "data")

USERS_FILE = os.path.join(DATA_DIR, "users.json")
ITINERARIES_FILE = os.path.join(DATA_DIR, "itineraries.json")
DESTINATIONS_FILE = os.path.join(DATA_DIR, "destinations.json")


# ---------------------------------------------------------------------------
# Generic file I/O helpers
# ---------------------------------------------------------------------------

def _read_json(filepath: str) -> list:
    """Read a JSON file and return its contents as a Python list.

    Returns an empty list if the file does not exist or is empty.
    """
    if not os.path.exists(filepath):
        return []
    with open(filepath, "r", encoding="utf-8") as fh:
        content = fh.read().strip()
        if not content:
            return []
        return json.loads(content)


def _write_json(filepath: str, data: list) -> None:
    """Serialise *data* and write it to *filepath* (pretty-printed)."""
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2)


# ---------------------------------------------------------------------------
# User helpers
# ---------------------------------------------------------------------------

def get_all_users() -> list:
    """Return all registered users."""
    return _read_json(USERS_FILE)


def get_user_by_username(username: str) -> dict | None:
    """Return the user dict for *username*, or None if not found."""
    users = get_all_users()
    for user in users:
        if user.get("username") == username:
            return user
    return None


def save_user(user: dict) -> None:
    """Append *user* to the users store."""
    users = get_all_users()
    users.append(user)
    _write_json(USERS_FILE, users)


# ---------------------------------------------------------------------------
# Destination helpers
# ---------------------------------------------------------------------------

def get_all_destinations() -> list:
    """Return all destinations from the static catalogue."""
    return _read_json(DESTINATIONS_FILE)


# ---------------------------------------------------------------------------
# Itinerary helpers
# ---------------------------------------------------------------------------

def get_all_itineraries() -> list:
    """Return all itineraries across all users."""
    return _read_json(ITINERARIES_FILE)


def get_itineraries_for_user(username: str) -> list:
    """Return itineraries that belong to *username*."""
    return [it for it in get_all_itineraries() if it.get("username") == username]


def save_itinerary(itinerary: dict) -> None:
    """Append *itinerary* to the itineraries store."""
    itineraries = get_all_itineraries()
    itineraries.append(itinerary)
    _write_json(ITINERARIES_FILE, itineraries)
