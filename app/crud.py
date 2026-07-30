from .data import read_data, write_data
from .auth import hash_password, verify_password
from datetime import datetime, timezone
import uuid

def register_user(username: str, password: str, email: str | None = None, interests: list[str] | None = None):
    data = read_data()
    if any(u["username"] == username for u in data.get("users", [])):
        return None
    user = {"id": str(uuid.uuid4()), "username": username, "password": hash_password(password)}
    if email:
        user["email"] = email
    if interests:
        user["interests"] = interests
    data.setdefault("users", []).append(user)
    write_data(data)
    return user

def authenticate_user(username: str, password: str):
    data = read_data()
    for u in data.get("users", []):
        # Google-only accounts have no "password" key - guard against that
        # rather than letting verify_password blow up on a missing hash.
        if u["username"] == username and u.get("password") and verify_password(password, u["password"]):
            return u
    return None

def get_user(username: str):
    data = read_data()
    for u in data.get("users", []):
        if u["username"] == username:
            return u
    return None

def _unique_username(data: dict, base: str) -> str:
    base = "".join(ch for ch in base.lower() if ch.isalnum()) or "traveller"
    existing = {u["username"] for u in data.get("users", [])}
    if base not in existing:
        return base
    i = 2
    while f"{base}{i}" in existing:
        i += 1
    return f"{base}{i}"

def get_or_create_google_user(google_sub: str, email: str | None, name: str | None):
    data = read_data()
    for u in data.get("users", []):
        if u.get("google_sub") == google_sub:
            return u
    base = (email.split("@")[0] if email else None) or name or "traveller"
    user = {
        "id": str(uuid.uuid4()),
        "username": _unique_username(data, base),
        "google_sub": google_sub,
    }
    if email:
        user["email"] = email
    data.setdefault("users", []).append(user)
    write_data(data)
    return user

def update_user_interests(username: str, interests: list[str]):
    data = read_data()
    for u in data.get("users", []):
        if u["username"] == username:
            u["interests"] = interests
            write_data(data)
            return u
    return None

def update_user_avatar(username: str, avatar_url: str):
    data = read_data()
    for u in data.get("users", []):
        if u["username"] == username:
            u["avatar_url"] = avatar_url
            write_data(data)
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

def get_destination(destination_id: str):
    data = read_data()
    for d in data.get("destinations", []):
        if d.get("id") == destination_id:
            return d
    return None

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

def _comment_score(c: dict) -> int:
    return len(c.get("upvotes", [])) - len(c.get("downvotes", []))

def _serialize_comment(c: dict, viewer: str | None, replies: list[dict]) -> dict:
    vote = None
    if viewer:
        if viewer in c.get("upvotes", []):
            vote = "up"
        elif viewer in c.get("downvotes", []):
            vote = "down"
    return {
        "id": c["id"],
        "destination_id": c["destination_id"],
        "parent_id": c.get("parent_id"),
        "username": c["username"],
        "text": c["text"],
        "created_at": c["created_at"],
        "score": _comment_score(c),
        "user_vote": vote,
        "replies": replies,
    }

def create_comment(destination_id: str, username: str, text: str, parent_id: str | None = None):
    data = read_data()
    if parent_id is not None:
        parent = next(
            (c for c in data.get("comments", []) if c["id"] == parent_id and c.get("destination_id") == destination_id),
            None,
        )
        if not parent:
            return None
    comment = {
        "id": str(uuid.uuid4()),
        "destination_id": destination_id,
        "parent_id": parent_id,
        "username": username,
        "text": text,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "upvotes": [],
        "downvotes": [],
    }
    data.setdefault("comments", []).append(comment)
    write_data(data)
    return _serialize_comment(comment, username, [])

def vote_comment(comment_id: str, username: str, direction: str):
    data = read_data()
    for c in data.get("comments", []):
        if c["id"] == comment_id:
            upvotes = set(c.get("upvotes", []))
            downvotes = set(c.get("downvotes", []))
            upvotes.discard(username)
            downvotes.discard(username)
            if direction == "up":
                upvotes.add(username)
            elif direction == "down":
                downvotes.add(username)
            c["upvotes"] = list(upvotes)
            c["downvotes"] = list(downvotes)
            write_data(data)
            return _serialize_comment(c, username, [])
    return None

def get_comments_for_destination(destination_id: str, viewer: str | None = None) -> list[dict]:
    data = read_data()
    all_comments = [c for c in data.get("comments", []) if c.get("destination_id") == destination_id]
    by_parent: dict[str | None, list[dict]] = {}
    for c in all_comments:
        by_parent.setdefault(c.get("parent_id"), []).append(c)

    def build(parent_id: str | None) -> list[dict]:
        nodes = by_parent.get(parent_id, [])
        if parent_id is None:
            # Top-level: highest score first, newest breaking ties.
            nodes = sorted(nodes, key=lambda c: (_comment_score(c), c["created_at"]), reverse=True)
        else:
            # Replies read top-to-bottom as a conversation, oldest first.
            nodes = sorted(nodes, key=lambda c: c["created_at"])
        return [_serialize_comment(c, viewer, build(c["id"])) for c in nodes]

    return build(None)

def recommendations_for(user: str):
    data = read_data()
    dests = data.get("destinations", [])
    profile = get_user(user)
    interests = set((profile or {}).get("interests") or [])

    if not interests:
        return dests[:3]

    def score(d):
        return len(set(d.get("tags") or []) & interests)

    matched = [d for d in dests if score(d) > 0]
    matched.sort(key=score, reverse=True)
    return matched[:6] if matched else dests[:3]
