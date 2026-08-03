import secrets
import uuid
from datetime import datetime, timedelta, timezone

from .auth import hash_password, verify_password
from .data import read_data, write_data

RESET_CODE_TTL = timedelta(minutes=30)


def _find_user(data: dict, identifier: str) -> dict | None:
    for u in data.get("users", []):
        if u.get("username") == identifier or u.get("email") == identifier:
            return u
    return None


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


def is_admin(username: str) -> bool:
    for u in read_data().get("users", []):
        if u.get("username") == username:
            return u.get("role") == "admin"
    return False


def create_password_reset(identifier: str) -> tuple[dict, str] | None:
    """identifier: username or email. Returns (user, plaintext_code) if a
    matching account with an email on file exists, else None - the caller
    must respond identically either way (see main.py) so this endpoint
    can't be used to check which usernames/emails are registered.
    """
    data = read_data()
    user = _find_user(data, identifier)
    if user is None or not user.get("email"):
        return None

    # Six digits rather than a long token: typed into the app by hand, not
    # clicked from a link - this app runs on Windows/Android/Web with no
    # deep-link handling set up, so a manually-entered code works
    # everywhere a clickable link wouldn't.
    code = f"{secrets.randbelow(1_000_000):06d}"
    reset = {
        "username": user["username"],
        # Reuses the same adaptive password hash as real passwords rather
        # than storing the code in plain text or a fast hash - a 6-digit
        # code is low-entropy, so resisting brute force on a stolen data
        # file matters more here than it costs in extra CPU at reset time.
        "code_hash": hash_password(code),
        "expires_at": (datetime.now(timezone.utc) + RESET_CODE_TTL).isoformat(),
    }
    resets = [
        r for r in data.get("password_resets", []) if r["username"] != user["username"]
    ]
    resets.append(reset)
    data["password_resets"] = resets
    write_data(data)
    return user, code


def reset_password(identifier: str, code: str, new_password: str) -> bool:
    """True if the password was changed. False covers every failure case
    uniformly (no such account, no pending reset, expired, wrong code) so
    a caller can't distinguish "wrong code" from "no such account" either.
    """
    data = read_data()
    user = _find_user(data, identifier)
    if user is None:
        return False

    resets = data.get("password_resets", [])
    reset = next((r for r in resets if r["username"] == user["username"]), None)
    if reset is None:
        return False
    if datetime.now(timezone.utc) > datetime.fromisoformat(reset["expires_at"]):
        return False
    if not verify_password(code, reset["code_hash"]):
        return False

    user["password"] = hash_password(new_password)
    data["password_resets"] = [r for r in resets if r["username"] != user["username"]]
    write_data(data)
    return True
