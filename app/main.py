import re
import unicodedata
from pathlib import Path

from fastapi import FastAPI, File, HTTPException, Depends, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from . import ai, crud, google_auth, routing, stats
from .schemas import (
    UserCreate,
    Token,
    Itinerary,
    Destination,
    ItineraryCreate,
    UserProfile,
    InterestsUpdate,
    GoogleAuthRequest,
    ChatRequest,
    ChatResponse,
    Comment,
    CommentCreate,
    VoteRequest,
    DestinationSubmit,
    DestinationUpdate,
    RatingRequest,
    RatingSummary,
    RouteRequest,
    RouteResponse,
)
from .auth import (
    create_access_token,
    get_current_user,
    get_optional_user,
    is_admin,
    require_admin,
)

app = FastAPI(title="GlobeTrotter Phase1")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

_static_dir = Path(__file__).resolve().parents[1] / "static"
_static_dir.mkdir(parents=True, exist_ok=True)
app.mount("/static", StaticFiles(directory=_static_dir), name="static")

# Profile pictures live on the VPS filesystem under static/, same durable
# location destination images already use (survives restarts/redeploys -
# it's part of the app dir, not a temp path). Never keyed by username: that
# comes straight from the client on /register and isn't sanitized, so using
# it in a filesystem path would be a traversal risk. The server-generated
# user id is always a safe uuid.
_avatars_dir = _static_dir / "avatars"
_avatars_dir.mkdir(parents=True, exist_ok=True)
# Same folder the 62 curated destination photos already live in - a user-
# or admin-uploaded destination image lands right alongside them, named from
# a slugified version of the destination's name (see _slugify) so the
# filename stays human-readable while still being safe against path
# traversal, since slugifying is what strips out anything dangerous.
_destinations_images_dir = _static_dir / "destinations"
_destinations_images_dir.mkdir(parents=True, exist_ok=True)
_IMAGE_MAX_BYTES = 5 * 1024 * 1024
_IMAGE_EXTENSIONS = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "image/gif": ".gif",
}


def _slugify(text: str) -> str:
    """ASCII, filesystem-safe slug - e.g. for naming an uploaded destination
    image after the destination's name. This is what actually makes it safe
    to build a path from user-supplied text: the output can only ever
    contain [a-z0-9_], so there's no path-traversal surface regardless of
    what was typed in."""
    normalized = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")
    return re.sub(r"[^a-z0-9]+", "_", normalized.lower()).strip("_")[:60]


@app.post("/register", response_model=Token)
def register(u: UserCreate):
    user = crud.register_user(u.username, u.password, u.email, u.interests)
    if not user:
        raise HTTPException(status_code=400, detail="User already exists")
    token = create_access_token(user["username"])
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
    user = crud.get_or_create_google_user(claims.get("sub"), claims.get("email"), claims.get("name"))
    token = create_access_token(user["username"])
    return {"access_token": token}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/stats/public")
def public_stats():
    return stats.get_public_stats()


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

    # Clear out any previous avatar for this user first, in case an earlier
    # upload used a different extension - otherwise stale files pile up.
    for existing in _avatars_dir.glob(f"{profile['id']}.*"):
        existing.unlink(missing_ok=True)

    dest = _avatars_dir / f"{profile['id']}{ext}"
    dest.write_bytes(body)

    updated = crud.update_user_avatar(user, f"/static/avatars/{dest.name}")
    return updated


@app.get("/me/favorites", response_model=list[Destination])
def get_favorites(user: str = Depends(get_current_user)):
    return crud.get_favorites_for(user)


@app.post("/me/favorites/{destination_id}", response_model=UserProfile)
def add_favorite(destination_id: str, user: str = Depends(get_current_user)):
    if not crud.get_destination(destination_id):
        raise HTTPException(status_code=404, detail="Destination not found")
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


@app.get("/destinations", response_model=list[Destination])
def destinations(q: str = None, user: str | None = Depends(get_optional_user)):
    # Anonymous callers (the public website) still get average/count; only
    # user_rating needs a signed-in viewer.
    return crud.search_destinations(q, viewer=user)


@app.get("/destinations/{destination_id}", response_model=Destination)
def get_destination(destination_id: str, user: str | None = Depends(get_optional_user)):
    dest = crud.get_destination(destination_id)
    if not dest or not crud.is_approved(dest):
        raise HTTPException(status_code=404, detail="Destination not found")
    return crud.enrich_destination(dest, viewer=user)


# ---------- Ratings ----------


@app.put("/destinations/{destination_id}/rating", response_model=RatingSummary)
def rate_destination(
    destination_id: str,
    payload: RatingRequest,
    user: str = Depends(get_current_user),
):
    if payload.stars < 1 or payload.stars > 5:
        raise HTTPException(status_code=400, detail="stars must be between 1 and 5")
    dest = crud.get_destination(destination_id)
    if not dest or not crud.is_approved(dest):
        raise HTTPException(status_code=404, detail="Destination not found")
    return crud.rate_destination(destination_id, user, payload.stars)


@app.delete("/destinations/{destination_id}/rating", response_model=RatingSummary)
def clear_rating(destination_id: str, user: str = Depends(get_current_user)):
    if not crud.get_destination(destination_id):
        raise HTTPException(status_code=404, detail="Destination not found")
    return crud.clear_rating(destination_id, user)


# ---------- User submissions ----------


@app.post("/destinations/submit", response_model=Destination)
def submit_destination(payload: DestinationSubmit, user: str = Depends(get_current_user)):
    name = (payload.name or "").strip()
    if not name:
        raise HTTPException(status_code=400, detail="Destination name is required")
    body = payload.dict()
    body["name"] = name
    return crud.submit_destination(body, user)


@app.get("/me/submissions", response_model=list[Destination])
def my_submissions(user: str = Depends(get_current_user)):
    return crud.get_submissions_by(user)


@app.post("/destinations/{destination_id}/image", response_model=Destination)
async def upload_destination_image(
    destination_id: str,
    file: UploadFile = File(...),
    user: str = Depends(get_current_user),
):
    dest = crud.get_destination(destination_id)
    if not dest:
        raise HTTPException(status_code=404, detail="Destination not found")
    # Only the person who proposed this destination, or an admin, may
    # attach/replace its photo - not just anyone with the id.
    if dest.get("submitted_by") != user and not is_admin(user):
        raise HTTPException(status_code=403, detail="Not allowed to modify this destination")

    ext = _IMAGE_EXTENSIONS.get((file.content_type or "").lower())
    if not ext:
        raise HTTPException(status_code=400, detail="Unsupported image type - use JPEG, PNG, WEBP or GIF")

    body = await file.read()
    if not body:
        raise HTTPException(status_code=400, detail="Empty file")
    if len(body) > _IMAGE_MAX_BYTES:
        raise HTTPException(status_code=400, detail="Image is larger than 5MB")

    # Human-readable filenames, matching the curated catalog's own images
    # (e.g. "le_safoutier.jpg"), rather than the opaque destination id.
    old_url = dest.get("image_url") or ""
    slug = _slugify(dest.get("name") or "") or destination_id
    dest_path = _destinations_images_dir / f"{slug}{ext}"
    if dest_path.exists() and old_url != f"/static/destinations/{dest_path.name}":
        # Another destination already has this slug (e.g. two destinations
        # named "Le Safoutier") - disambiguate instead of overwriting it.
        slug = f"{slug}-{destination_id}"
        dest_path = _destinations_images_dir / f"{slug}{ext}"

    # Remove this destination's previous image file, whatever it was named -
    # a prior upload under a different slug/extension - so a later name edit
    # doesn't leave orphaned files behind.
    if old_url.startswith("/static/destinations/"):
        stale = _static_dir / "destinations" / Path(old_url).name
        if stale.exists() and stale != dest_path:
            stale.unlink(missing_ok=True)
    for existing in _destinations_images_dir.glob(f"{slug}.*"):
        existing.unlink(missing_ok=True)

    dest_path.write_bytes(body)

    updated = crud.update_destination(destination_id, {"image_url": f"/static/destinations/{dest_path.name}"})
    return crud.enrich_destination(updated, viewer=user)


# ---------- Admin ----------


@app.get("/admin/destinations", response_model=list[Destination])
def admin_list_destinations(status: str = None, admin: str = Depends(require_admin)):
    return crud.list_destinations_by_status(status)


@app.patch("/admin/destinations/{destination_id}", response_model=Destination)
def admin_update_destination(
    destination_id: str,
    payload: DestinationUpdate,
    admin: str = Depends(require_admin),
):
    changes = {k: v for k, v in payload.dict().items() if v is not None}
    if changes.get("status") and changes["status"] not in (
        crud.APPROVED,
        crud.PENDING,
        crud.REJECTED,
    ):
        raise HTTPException(status_code=400, detail="Invalid status")
    updated = crud.update_destination(destination_id, changes)
    if not updated:
        raise HTTPException(status_code=404, detail="Destination not found")
    return updated


@app.post("/admin/destinations", response_model=Destination)
def admin_create_destination(payload: DestinationSubmit, admin: str = Depends(require_admin)):
    name = (payload.name or "").strip()
    if not name:
        raise HTTPException(status_code=400, detail="Destination name is required")
    body = payload.dict()
    body["name"] = name
    created = crud.submit_destination(body, admin)
    # Anything an admin adds directly is live immediately - it doesn't need
    # to sit in the same review queue they're the reviewer for.
    return crud.update_destination(created["id"], {"status": crud.APPROVED})


@app.delete("/admin/destinations/{destination_id}")
def admin_delete_destination(destination_id: str, admin: str = Depends(require_admin)):
    if not crud.delete_destination(destination_id):
        raise HTTPException(status_code=404, detail="Destination not found")
    return {"deleted": destination_id}


_COMMENT_MAX_CHARS = 2000


@app.get("/destinations/{destination_id}/comments", response_model=list[Comment])
def get_comments(destination_id: str, user: str = Depends(get_current_user)):
    if not crud.get_destination(destination_id):
        raise HTTPException(status_code=404, detail="Destination not found")
    return crud.get_comments_for_destination(destination_id, viewer=user)


@app.post("/destinations/{destination_id}/comments", response_model=Comment)
def post_comment(destination_id: str, payload: CommentCreate, user: str = Depends(get_current_user)):
    if not crud.get_destination(destination_id):
        raise HTTPException(status_code=404, detail="Destination not found")
    text = payload.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Comment text is required")
    if len(text) > _COMMENT_MAX_CHARS:
        raise HTTPException(status_code=400, detail=f"Comment must be under {_COMMENT_MAX_CHARS} characters")
    comment = crud.create_comment(destination_id, user, text, payload.parent_id)
    if comment is None:
        raise HTTPException(status_code=400, detail="Parent comment not found")
    return comment


@app.post("/comments/{comment_id}/vote", response_model=Comment)
def vote_comment(comment_id: str, payload: VoteRequest, user: str = Depends(get_current_user)):
    if payload.direction not in ("up", "down", "none"):
        raise HTTPException(status_code=400, detail="direction must be 'up', 'down' or 'none'")
    comment = crud.vote_comment(comment_id, user, payload.direction)
    if comment is None:
        raise HTTPException(status_code=404, detail="Comment not found")
    return comment


@app.get("/recommendations", response_model=list[Destination])
def recommendations(user: str = Depends(get_current_user)):
    return crud.recommendations_for(user)


@app.post("/itineraries", response_model=Itinerary)
def create_itinerary(itin: ItineraryCreate, user: str = Depends(get_current_user)):
    data = itin.dict()
    data["user"] = user
    return crud.create_itinerary(data)


@app.get("/itineraries", response_model=list[Itinerary])
def list_itineraries(user: str = Depends(get_current_user)):
    return crud.get_itineraries_for(user)


@app.delete("/itineraries/{itinerary_id}")
def delete_itinerary(itinerary_id: str, user: str = Depends(get_current_user)):
    if not crud.delete_itinerary(itinerary_id, user):
        raise HTTPException(status_code=404, detail="Itinerary not found")
    return {"deleted": itinerary_id}


def _ai_error_response(exc: Exception):
    if isinstance(exc, ai.AiNotConfiguredError):
        return HTTPException(status_code=503, detail="AI assistant is not configured")
    return HTTPException(status_code=502, detail="AI assistant is temporarily unavailable")


@app.post("/ai/chat", response_model=ChatResponse)
async def ai_chat(payload: ChatRequest, user: str = Depends(get_current_user)):
    if not payload.messages:
        raise HTTPException(status_code=400, detail="messages must not be empty")
    profile = crud.get_user(user)
    interests = (profile or {}).get("interests") or []
    try:
        reply = await ai.chat(
            [m.dict() for m in payload.messages],
            interests=interests,
            language_code=payload.language_code,
        )
    except (ai.AiNotConfiguredError, ai.AiRequestError) as exc:
        raise _ai_error_response(exc)
    return {"reply": reply}


@app.post("/ai/explain/{destination_id}", response_model=ChatResponse)
async def ai_explain(
    destination_id: str,
    language_code: str | None = None,
    user: str = Depends(get_current_user),
):
    dest = crud.get_destination(destination_id)
    if not dest:
        raise HTTPException(status_code=404, detail="Destination not found")

    cached = dest.get("ai_explanation")
    if cached and not language_code:
        return {"reply": cached}

    try:
        reply = await ai.explain_destination(
            dest,
            language_code=language_code,
        )
    except (ai.AiNotConfiguredError, ai.AiRequestError) as exc:
        raise _ai_error_response(exc)
    if not language_code:
        crud.set_destination_ai_explanation(destination_id, reply)
    return {"reply": reply}


@app.post("/route", response_model=RouteResponse)
async def get_route(payload: RouteRequest, user: str = Depends(get_current_user)):
    if len(payload.waypoints) < 2:
        raise HTTPException(status_code=400, detail="At least two waypoints are required")
    try:
        result = await routing.get_route(
            [(wp.lat, wp.lon) for wp in payload.waypoints],
            profile=payload.profile,
        )
    except routing.RoutingNotConfiguredError:
        raise HTTPException(status_code=503, detail="Routing is not configured")
    except routing.RoutingRequestError:
        raise HTTPException(status_code=502, detail="Routing service is temporarily unavailable")
    return result


# Mounted last (and most-specific-first) so none of these can shadow the
# API routes above: Starlette matches routes in registration order, and a
# mount at "/" would otherwise catch everything.
_website_dir = Path(__file__).resolve().parents[1] / "website"
_downloads_dir = _website_dir / "downloads"
_webapp_dir = _website_dir / "webapp"
_downloads_dir.mkdir(parents=True, exist_ok=True)
_webapp_dir.mkdir(parents=True, exist_ok=True)

app.mount("/downloads", StaticFiles(directory=_downloads_dir), name="downloads")
app.mount("/app", StaticFiles(directory=_webapp_dir, html=True), name="webapp")
app.mount("/", StaticFiles(directory=_website_dir, html=True), name="website")
