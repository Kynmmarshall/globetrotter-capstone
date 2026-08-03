import uuid

from .data import read_data, write_data


def create_itinerary(itin: dict):
    data = read_data()
    itin["id"] = str(uuid.uuid4())
    data.setdefault("itineraries", []).append(itin)
    write_data(data)
    return itin


def get_itineraries_for(user: str):
    data = read_data()
    return [i for i in data.get("itineraries", []) if i.get("user") == user]


def update_itinerary(itinerary_id: str, username: str, updates: dict) -> dict | None:
    data = read_data()
    for i in data.get("itineraries", []):
        if i.get("id") == itinerary_id and i.get("user") == username:
            i.update({k: v for k, v in updates.items() if v is not None})
            write_data(data)
            return i
    return None


def delete_itinerary(itinerary_id: str, username: str) -> bool:
    data = read_data()
    itineraries = data.get("itineraries", [])
    before = len(itineraries)
    data["itineraries"] = [
        i for i in itineraries if not (i.get("id") == itinerary_id and i.get("user") == username)
    ]
    if len(data["itineraries"]) == before:
        return False
    write_data(data)
    return True


def get_or_create_share_token(itinerary_id: str, username: str) -> str | None:
    """Idempotent - re-sharing an already-shared itinerary returns the same
    token rather than minting a new one and orphaning the old link (which
    someone may have already saved/sent to a travel companion).
    """
    data = read_data()
    for i in data.get("itineraries", []):
        if i.get("id") == itinerary_id and i.get("user") == username:
            token = i.get("share_token")
            if not token:
                token = uuid.uuid4().hex
                i["share_token"] = token
                write_data(data)
            return token
    return None


def revoke_share_token(itinerary_id: str, username: str) -> bool:
    data = read_data()
    for i in data.get("itineraries", []):
        if i.get("id") == itinerary_id and i.get("user") == username:
            had_token = bool(i.get("share_token"))
            i.pop("share_token", None)
            if had_token:
                write_data(data)
            return had_token
    return False


def get_itinerary_by_share_token(token: str) -> dict | None:
    for i in read_data().get("itineraries", []):
        if i.get("share_token") == token:
            return i
    return None
