from datetime import datetime, timedelta, timezone

from .data import read_data, write_data

# How long after posting a comment/reply its author may still edit or
# delete it - after this it's permanent, same as most forums/social apps.
COMMENT_EDIT_WINDOW = timedelta(minutes=5)


class CommentNotOwnedError(Exception):
    """Raised when the caller isn't the comment's original author."""


class CommentEditWindowExpiredError(Exception):
    """Raised once COMMENT_EDIT_WINDOW has passed since posting."""


class CommentHasRepliesError(Exception):
    """Raised on delete when other comments already reply to this one -
    removing it would either orphan those replies or silently destroy
    someone else's content, so it's blocked rather than either of those."""

APPROVED = "approved"
PENDING = "pending"
REJECTED = "rejected"


def is_approved(d: dict) -> bool:
    return d.get("status", APPROVED) == APPROVED


def get_destination(destination_id: str):
    data = read_data()
    for d in data.get("destinations", []):
        if d.get("id") == destination_id:
            return d
    return None


def set_destination_ai_explanation(destination_id: str, text: str):
    data = read_data()
    for d in data.get("destinations", []):
        if d.get("id") == destination_id:
            d["ai_explanation"] = text
            write_data(data)
            return d
    return None


def _rating_stats(data: dict) -> dict:
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


def _comment_counts(data: dict) -> dict:
    counts: dict[str, int] = {}
    for c in data.get("comments", []):
        did = c.get("destination_id")
        if did:
            counts[did] = counts.get(did, 0) + 1
    return counts


def _with_ratings(dest: dict, stats: dict, mine: dict, comment_counts: dict | None = None) -> dict:
    average, count = stats.get(dest["id"], (None, 0))
    return {
        **dest,
        "rating_average": average,
        "rating_count": count,
        "user_rating": mine.get(dest["id"]),
        "comment_count": (comment_counts or {}).get(dest["id"], 0),
    }


def enrich_destinations(dests: list[dict], viewer: str | None = None) -> list[dict]:
    data = read_data()
    stats = _rating_stats(data)
    mine = _viewer_ratings(data, viewer)
    comment_counts = _comment_counts(data)
    return [_with_ratings(d, stats, mine, comment_counts) for d in dests]


def enrich_destination(dest: dict, viewer: str | None = None) -> dict:
    return enrich_destinations([dest], viewer)[0]


def get_destinations_by_ids(ids: list[str], viewer: str | None = None) -> list[dict]:
    """Backs GET /internal/destinations - the sync call user_service makes
    to hydrate a viewer's favorite_ids into full Destination objects."""
    data = read_data()
    by_id = {d["id"]: d for d in data.get("destinations", []) if is_approved(d)}
    ordered = [by_id[i] for i in ids if i in by_id]
    stats = _rating_stats(data)
    mine = _viewer_ratings(data, viewer)
    comment_counts = _comment_counts(data)
    return [_with_ratings(d, stats, mine, comment_counts) for d in ordered]


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
    comment_counts = _comment_counts(data)
    return [_with_ratings(d, stats, mine, comment_counts) for d in dests]


def rate_destination(destination_id: str, username: str, stars: int):
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
    data["ratings"] = [r for r in data.get("ratings", []) if r.get("destination_id") != destination_id]
    data["comments"] = [c for c in data.get("comments", []) if c.get("destination_id") != destination_id]
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
    import uuid

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


def _parse_created_at(raw: str) -> datetime:
    dt = datetime.fromisoformat(raw)
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)


def _require_editable(comment: dict, username: str) -> None:
    if comment.get("username") != username:
        raise CommentNotOwnedError()
    if datetime.now(timezone.utc) - _parse_created_at(comment["created_at"]) > COMMENT_EDIT_WINDOW:
        raise CommentEditWindowExpiredError()


def update_comment(comment_id: str, username: str, text: str) -> dict | None:
    """Returns the updated comment, None if not found, or raises
    CommentNotOwnedError / CommentEditWindowExpiredError."""
    data = read_data()
    for c in data.get("comments", []):
        if c["id"] == comment_id:
            _require_editable(c, username)
            c["text"] = text
            write_data(data)
            return _serialize_comment(c, username, [])
    return None


def delete_comment(comment_id: str, username: str) -> bool | None:
    """Returns True on success, None if not found, or raises
    CommentNotOwnedError / CommentEditWindowExpiredError / CommentHasRepliesError."""
    data = read_data()
    comments = data.get("comments", [])
    target = next((c for c in comments if c["id"] == comment_id), None)
    if target is None:
        return None
    _require_editable(target, username)
    if any(c.get("parent_id") == comment_id for c in comments):
        raise CommentHasRepliesError()
    data["comments"] = [c for c in comments if c["id"] != comment_id]
    write_data(data)
    return True


def get_comments_for_destination(destination_id: str, viewer: str | None = None) -> list[dict]:
    data = read_data()
    all_comments = [c for c in data.get("comments", []) if c.get("destination_id") == destination_id]
    by_parent: dict[str | None, list[dict]] = {}
    for c in all_comments:
        by_parent.setdefault(c.get("parent_id"), []).append(c)

    def build(parent_id: str | None) -> list[dict]:
        nodes = by_parent.get(parent_id, [])
        if parent_id is None:
            nodes = sorted(nodes, key=lambda c: (_comment_score(c), c["created_at"]), reverse=True)
        else:
            nodes = sorted(nodes, key=lambda c: c["created_at"])
        return [_serialize_comment(c, viewer, build(c["id"])) for c in nodes]

    return build(None)


def recommendations_for(interests: list[str], visited_destination_ids: set[str] | None = None, viewer: str | None = None):
    """Interests come from User Service and past-trip destination ids from
    Itinerary Service - both fetched by the caller (see main.py) via the
    sync inter-service clients, since this service doesn't own either."""
    data = read_data()
    dests = [d for d in data.get("destinations", []) if is_approved(d)]

    stats = _rating_stats(data)
    mine = _viewer_ratings(data, viewer)
    comment_counts = _comment_counts(data)

    def finish(items):
        return [_with_ratings(d, stats, mine, comment_counts) for d in items]

    visited = visited_destination_ids or set()
    candidates = [d for d in dests if d["id"] not in visited] or dests

    if not interests:
        return finish(candidates[:3])

    interest_set = set(interests)

    def score(d):
        return len(set(d.get("tags") or []) & interest_set)

    matched = [d for d in candidates if score(d) > 0]
    matched.sort(key=score, reverse=True)
    return finish(matched[:6] if matched else candidates[:3])
