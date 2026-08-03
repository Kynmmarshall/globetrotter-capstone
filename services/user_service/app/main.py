from pathlib import Path

from fastapi import FastAPI, File, HTTPException, Depends, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from . import clients, crud, email_util, events, google_auth
from .schemas import (
    UserCreate,
    Token,
    UserProfile,
    InterestsUpdate,
    GoogleAuthRequest,
    Destination,
    InternalUserProfile,
    PasswordResetRequest,
    PasswordReset,
)
from .auth import create_access_token, get_current_user, require_internal

app = FastAPI(title="trip_io User Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

_static_dir = Path(__file__).resolve().parents[1] / "static"
_avatars_dir = _static_dir / "avatars"
_avatars_dir.mkdir(parents=True, exist_ok=True)
app.mount("/static/avatars", StaticFiles(directory=_avatars_dir), name="avatars")

_IMAGE_MAX_BYTES = 5 * 1024 * 1024
_IMAGE_EXTENSIONS = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "image/gif": ".gif",
}


@app.get("/health")
def health():
    return {"status": "ok", "service": "user_service"}


@app.post("/register", response_model=Token)
def register(u: UserCreate):
    user = crud.register_user(u.username, u.password, u.email, u.interests)
    if not user:
        raise HTTPException(status_code=400, detail="User already exists")
    token = create_access_token(user["username"])
    events.publish("user.registered", {"username": user["username"], "interests": u.interests or []})
    return {"access_token": token}


@app.post("/login", response_model=Token)
def login(u: UserCreate):
    user = crud.authenticate_user(u.username, u.password)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = create_access_token(user["username"])
    return {"access_token": token}


@app.post("/auth/google", response_model=Token)
async def auth_google(payload: GoogleAuthRequest):
    try:
        claims = await google_auth.verify_id_token(payload.id_token)
    except google_auth.GoogleTokenError as exc:
        raise HTTPException(status_code=401, detail=str(exc))
    existing = any(
        u.get("google_sub") == claims.get("sub") for u in crud.read_data().get("users", [])
    )
    user = crud.get_or_create_google_user(claims.get("sub"), claims.get("email"), claims.get("name"))
    token = create_access_token(user["username"])
    if not existing:
        events.publish("user.registered", {"username": user["username"], "interests": []})
    return {"access_token": token}


@app.post("/auth/request-password-reset")
def request_password_reset(payload: PasswordResetRequest):
    result = crud.create_password_reset(payload.identifier)
    if result:
        user, code = result
        email_util.send_password_reset_code(user["email"], code)
    # Always the same response whether or not an account matched -
    # otherwise this endpoint could be used to check which usernames or
    # emails are registered.
    return {"detail": "If an account exists, a reset code has been sent."}


@app.post("/auth/reset-password")
def reset_password(payload: PasswordReset):
    if len(payload.new_password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")
    if not crud.reset_password(payload.identifier, payload.code, payload.new_password):
        raise HTTPException(status_code=400, detail="Invalid or expired reset code")
    return {"detail": "Password updated"}


@app.get("/me", response_model=UserProfile)
def me(user: str = Depends(get_current_user)):
    profile = crud.get_user(user)
    if not profile:
        raise HTTPException(status_code=404, detail="User not found")
    return profile


@app.put("/me/interests", response_model=UserProfile)
def update_interests(payload: InterestsUpdate, user: str = Depends(get_current_user)):
    profile = crud.update_user_interests(user, payload.interests)
    if not profile:
        raise HTTPException(status_code=404, detail="User not found")
    return profile


@app.post("/me/avatar", response_model=UserProfile)
async def upload_avatar(file: UploadFile = File(...), user: str = Depends(get_current_user)):
    profile = crud.get_user(user)
    if not profile:
        raise HTTPException(status_code=404, detail="User not found")

    ext = _IMAGE_EXTENSIONS.get((file.content_type or "").lower())
    if not ext:
        raise HTTPException(status_code=400, detail="Unsupported image type - use JPEG, PNG, WEBP or GIF")

    body = await file.read()
    if not body:
        raise HTTPException(status_code=400, detail="Empty file")
    if len(body) > _IMAGE_MAX_BYTES:
        raise HTTPException(status_code=400, detail="Image is larger than 5MB")

    for existing in _avatars_dir.glob(f"{profile['id']}.*"):
        existing.unlink(missing_ok=True)

    dest = _avatars_dir / f"{profile['id']}{ext}"
    dest.write_bytes(body)

    updated = crud.update_user_avatar(user, f"/static/avatars/{dest.name}")
    return updated


@app.get("/me/favorites", response_model=list[Destination])
async def get_favorites(user: str = Depends(get_current_user)):
    profile = crud.get_user(user)
    fav_ids = (profile or {}).get("favorite_ids") or []
    return await clients.get_destinations_by_ids(fav_ids, viewer=user)


@app.post("/me/favorites/{destination_id}", response_model=UserProfile)
def add_favorite(destination_id: str, user: str = Depends(get_current_user)):
    # Deliberately doesn't verify the destination exists (that would mean
    # calling recommendation_service synchronously on every favorite toggle)
    # - a favorite pointing at a since-deleted destination just won't
    # hydrate to anything in GET /me/favorites, which is a harmless no-op.
    profile = crud.add_favorite(user, destination_id)
    if not profile:
        raise HTTPException(status_code=404, detail="User not found")
    return profile


@app.delete("/me/favorites/{destination_id}", response_model=UserProfile)
def remove_favorite(destination_id: str, user: str = Depends(get_current_user)):
    profile = crud.remove_favorite(user, destination_id)
    if not profile:
        raise HTTPException(status_code=404, detail="User not found")
    return profile


# ---------- Internal (service-to-service only, never through the Gateway) ----------


@app.get("/internal/users/count")
def internal_user_count(_=Depends(require_internal)):
    return {"count": len(crud.read_data().get("users", []))}


# Registered after /internal/users/count on purpose - FastAPI matches
# routes in registration order, and {username} would otherwise swallow
# literal "count" as a username, since a path parameter matches any string.
@app.get("/internal/users/{username}", response_model=InternalUserProfile)
def internal_get_user(username: str, _=Depends(require_internal)):
    profile = crud.get_user(username)
    if not profile:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "username": profile["username"],
        "interests": profile.get("interests") or [],
        "is_admin": profile.get("role") == "admin",
    }
