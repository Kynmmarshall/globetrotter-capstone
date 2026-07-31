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

def add_favorite(username: str, destination_id: str):
    data = read_data()
    for u in data.get("users", []):
        if u["username"] == username:
            favs = u.setdefault("favorite_ids", [])
            if destination_id not in favs:
                # Newest-first, so the Favorites tab shows what was just
                # saved at the top rather than buried at the bottom.
                favs.insert(0, destination_id)
            write_data(data)
            return u
    return None

def remove_favorite(username: str, destination_id: str):
    data = read_data()
    for u in data.get("users", []):
        if u["username"] == username:
            favs = u.setdefault("favorite_ids", [])
            if destination_id in favs:
                favs.remove(destination_id)
            write_data(data)
            return u
    return None

def get_favorites_for(username: str):
    data = read_data()
    profile = get_user(username)
    fav_ids = (profile or {}).get("favorite_ids") or []
    dests_by_id = {
        d["id"]: d for d in data.get("destinations", []) if is_approved(d)
    }
    favs = [dests_by_id[i] for i in fav_ids if i in dests_by_id]
    stats = _rating_stats(data)
    mine = _viewer_ratings(data, username)
    return [_with_ratings(d, stats, mine) for d in favs]

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

def get_destination(destination_id: str):
    data = read_data()
    for d in data.get("destinations", []):
        if d.get("id") == destination_id:
            return d
    return None

def set_destination_ai_explanation(destination_id: str, text: str):
    # Explanations are generated from a destination's own (static) fields,
    # so the same destination always produces the same answer - caching it
    # here means every user after the first gets it for free, with zero
    # Groq quota spent.
    data = read_data()
    for d in data.get("destinations", []):
        if d.get("id") == destination_id:
            d["ai_explanation"] = text
            write_data(data)
            return d
    return None

APPROVED = "approved"
PENDING = "pending"
REJECTED = "rejected"

def is_approved(d: dict) -> bool:
    # Destinations created before moderation existed have no "status" key,
    # so a missing status means approved rather than hidden.
    return d.get("status", APPROVED) == APPROVED

def _rating_stats(data: dict) -> dict:
    """{destination_id: (average, count)} across all stored ratings."""
    buckets: dict[str, list[int]] = {}
    for r in data.get("ratings", []):
        buckets.setdefault(r["destination_id"], []).append(int(r["stars"]))
    return {
        did: (round(sum(stars) / len(stars), 2), len(stars))
        for did, stars in buckets.items()
        if stars
    }

def _viewer_ratings(data: dict, viewer: str | None) -> dict:
    if not viewer:
        return {}
    return {
        r["destination_id"]: int(r["stars"])
        for r in data.get("ratings", [])
        if r.get("username") == viewer
    }

def _with_ratings(dest: dict, stats: dict, mine: dict) -> dict:
    average, count = stats.get(dest["id"], (None, 0))
    return {
        **dest,
        "rating_average": average,
        "rating_count": count,
        "user_rating": mine.get(dest["id"]),
    }

def enrich_destinations(dests: list[dict], viewer: str | None = None) -> list[dict]:
    data = read_data()
    stats = _rating_stats(data)
    mine = _viewer_ratings(data, viewer)
    return [_with_ratings(d, stats, mine) for d in dests]

def enrich_destination(dest: dict, viewer: str | None = None) -> dict:
    return enrich_destinations([dest], viewer)[0]

def search_destinations(q: str = None, viewer: str | None = None):
    data = read_data()
    dests = [d for d in data.get("destinations", []) if is_approved(d)]
    if q:
        ql = q.lower()
        def match(d):
            name = (d.get("name") or "").lower()
            tags = [t or "" for t in d.get("tags", [])]
            return ql in name or any(ql in t.lower() for t in tags)
        dests = [d for d in dests if match(d)]
    stats = _rating_stats(data)
    mine = _viewer_ratings(data, viewer)
    return [_with_ratings(d, stats, mine) for d in dests]

def rate_destination(destination_id: str, username: str, stars: int):
    """Upserts this user's rating - one per user per destination, so
    re-rating replaces rather than stacking."""
    data = read_data()
    ratings = data.setdefault("ratings", [])
    for r in ratings:
        if r["destination_id"] == destination_id and r["username"] == username:
            r["stars"] = stars
            r["updated_at"] = datetime.now(timezone.utc).isoformat()
            break
    else:
        ratings.append({
            "destination_id": destination_id,
            "username": username,
            "stars": stars,
            "created_at": datetime.now(timezone.utc).isoformat(),
        })
    write_data(data)
    return rating_summary(destination_id, username)

def clear_rating(destination_id: str, username: str):
    data = read_data()
    ratings = data.setdefault("ratings", [])
    data["ratings"] = [
        r for r in ratings
        if not (r["destination_id"] == destination_id and r["username"] == username)
    ]
    write_data(data)
    return rating_summary(destination_id, username)

def rating_summary(destination_id: str, viewer: str | None = None) -> dict:
    data = read_data()
    average, count = _rating_stats(data).get(destination_id, (None, 0))
    return {
        "destination_id": destination_id,
        "rating_average": average,
        "rating_count": count,
        "user_rating": _viewer_ratings(data, viewer).get(destination_id),
    }

def _next_destination_id(data: dict) -> str:
    highest = 0
    for d in data.get("destinations", []):
        raw = str(d.get("id", ""))
        if raw.startswith("d") and raw[1:].isdigit():
            highest = max(highest, int(raw[1:]))
    return f"d{highest + 1}"

def submit_destination(payload: dict, username: str):
    """A regular user's proposal - lands as PENDING, never live."""
    data = read_data()
    dest = {
        **payload,
        "id": _next_destination_id(data),
        "status": PENDING,
        "submitted_by": username,
        "submitted_at": datetime.now(timezone.utc).isoformat(),
    }
    data.setdefault("destinations", []).append(dest)
    write_data(data)
    return dest

def list_destinations_by_status(status: str | None = None):
    data = read_data()
    dests = data.get("destinations", [])
    if status:
        return [d for d in dests if d.get("status", APPROVED) == status]
    return dests

def get_submissions_by(username: str):
    data = read_data()
    return [d for d in data.get("destinations", []) if d.get("submitted_by") == username]

def update_destination(destination_id: str, changes: dict):
    data = read_data()
    for d in data.get("destinations", []):
        if d.get("id") == destination_id:
            for key, value in changes.items():
                if value is not None:
                    d[key] = value
            write_data(data)
            return d
    return None

def delete_destination(destination_id: str):
    data = read_data()
    before = len(data.get("destinations", []))
    data["destinations"] = [d for d in data.get("destinations", []) if d.get("id") != destination_id]
    if len(data["destinations"]) == before:
        return False
    # Clean up anything that pointed at it, so the app never renders an
    # orphaned rating or comment against a destination that's gone.
    data["ratings"] = [r for r in data.get("ratings", []) if r.get("destination_id") != destination_id]
    data["comments"] = [c for c in data.get("comments", []) if c.get("destination_id") != destination_id]
    for u in data.get("users", []):
        favs = u.get("favorite_ids")
        if favs and destination_id in favs:
            favs.remove(destination_id)
    write_data(data)
    return True

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
    dests = [d for d in data.get("destinations", []) if is_approved(d)]
    profile = get_user(user)
    interests = set((profile or {}).get("interests") or [])

    stats = _rating_stats(data)
    mine = _viewer_ratings(data, user)
    def finish(items):
        return [_with_ratings(d, stats, mine) for d in items]

    if not interests:
        return finish(dests[:3])

    def score(d):
        return len(set(d.get("tags") or []) & interests)

    matched = [d for d in dests if score(d) > 0]
    matched.sort(key=score, reverse=True)
    return finish(matched[:6] if matched else dests[:3])
