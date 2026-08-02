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
