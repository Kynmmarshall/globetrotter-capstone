from .data import read_data, write_data
from .auth import hash_password, verify_password
import uuid

def register_user(username: str, password: str, email: str | None = None):
    data = read_data()
    if any(u["username"] == username for u in data.get("users", [])):
        return None
    user = {"id": str(uuid.uuid4()), "username": username, "password": hash_password(password)}
    if email:
        user["email"] = email
    data.setdefault("users", []).append(user)
    write_data(data)
    return user

def authenticate_user(username: str, password: str):
    data = read_data()
    for u in data.get("users", []):
        if u["username"] == username and verify_password(password, u["password"]):
            return u
    return None

def create_itinerary(itin: dict):
    data = read_data()
    itin["id"] = str(uuid.uuid4())
    data.setdefault("itineraries", []).append(itin)
    write_data(data)
    return itin

def get_itineraries_for(user: str):
    data = read_data()
    return [i for i in data.get("itineraries", []) if i.get("user") == user]

def search_destinations(q: str = None):
    data = read_data()
    dests = data.get("destinations", [])
    if not q:
        return dests
    ql = q.lower()
    def match(d):
        name = (d.get("name") or "").lower()
        tags = [t or "" for t in d.get("tags", [])]
        return ql in name or any(ql in t.lower() for t in tags)
    return [d for d in dests if match(d)]

def recommendations_for(user: str):
    data = read_data()
    # simple: return top 3 popular destinations
    return data.get("destinations", [])[:3]
