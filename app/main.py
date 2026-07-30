from pathlib import Path

from fastapi import FastAPI, File, HTTPException, Depends, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from . import ai, crud, google_auth, stats
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
)
from .auth import create_access_token, get_current_user

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
_AVATAR_MAX_BYTES = 5 * 1024 * 1024
_AVATAR_EXTENSIONS = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "image/gif": ".gif",
}


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

    ext = _AVATAR_EXTENSIONS.get((file.content_type or "").lower())
    if not ext:
        raise HTTPException(status_code=400, detail="Unsupported image type - use JPEG, PNG, WEBP or GIF")

    body = await file.read()
    if not body:
        raise HTTPException(status_code=400, detail="Empty file")
    if len(body) > _AVATAR_MAX_BYTES:
        raise HTTPException(status_code=400, detail="Image is larger than 5MB")

    # Clear out any previous avatar for this user first, in case an earlier
    # upload used a different extension - otherwise stale files pile up.
    for existing in _avatars_dir.glob(f"{profile['id']}.*"):
        existing.unlink(missing_ok=True)

    dest = _avatars_dir / f"{profile['id']}{ext}"
    dest.write_bytes(body)

    updated = crud.update_user_avatar(user, f"/static/avatars/{dest.name}")
    return updated


@app.get("/destinations", response_model=list[Destination])
def destinations(q: str = None):
    return crud.search_destinations(q)


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
        reply = await ai.chat([m.dict() for m in payload.messages], interests=interests)
    except (ai.AiNotConfiguredError, ai.AiRequestError) as exc:
        raise _ai_error_response(exc)
    return {"reply": reply}


@app.post("/ai/explain/{destination_id}", response_model=ChatResponse)
async def ai_explain(destination_id: str, user: str = Depends(get_current_user)):
    dest = crud.get_destination(destination_id)
    if not dest:
        raise HTTPException(status_code=404, detail="Destination not found")
    try:
        reply = await ai.explain_destination(dest)
    except (ai.AiNotConfiguredError, ai.AiRequestError) as exc:
        raise _ai_error_response(exc)
    return {"reply": reply}


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
