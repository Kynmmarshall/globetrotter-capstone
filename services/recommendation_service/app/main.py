import re
import unicodedata
from pathlib import Path

from fastapi import FastAPI, File, HTTPException, Depends, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from . import ai, amenities, clients, crud, events, events_consumer, routing
from .schemas import (
    Amenity,
    Destination,
    DestinationSubmit,
    DestinationUpdate,
    RatingRequest,
    RatingSummary,
    ChatRequest,
    ChatResponse,
    Comment,
    CommentCreate,
    CommentUpdate,
    VoteRequest,
    RouteRequest,
    RouteResponse,
)
from .auth import get_current_user, get_optional_user, require_admin, require_internal

app = FastAPI(title="trip_io Recommendation Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def _startup():
    events_consumer.start_background_consumer()


_static_dir = Path(__file__).resolve().parents[1] / "static"
_destinations_images_dir = _static_dir / "destinations"
_destinations_images_dir.mkdir(parents=True, exist_ok=True)
app.mount("/static/destinations", StaticFiles(directory=_destinations_images_dir), name="destinations_static")

_IMAGE_MAX_BYTES = 5 * 1024 * 1024
_IMAGE_EXTENSIONS = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "image/gif": ".gif",
}
_COMMENT_MAX_CHARS = 2000


def _slugify(text: str) -> str:
    """ASCII, filesystem-safe slug - see the monolith's version of this for
    the full path-traversal-safety rationale, unchanged here."""
    normalized = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")
    return re.sub(r"[^a-z0-9]+", "_", normalized.lower()).strip("_")[:60]


@app.get("/health")
def health():
    return {"status": "ok", "service": "recommendation_service"}


@app.get("/destinations", response_model=list[Destination])
def destinations(q: str = None, user: str | None = Depends(get_optional_user)):
    return crud.search_destinations(q, viewer=user)


@app.get("/destinations/{destination_id}", response_model=Destination)
def get_destination(destination_id: str, user: str | None = Depends(get_optional_user)):
    dest = crud.get_destination(destination_id)
    if not dest or not crud.is_approved(dest):
        raise HTTPException(status_code=404, detail="Destination not found")
    return crud.enrich_destination(dest, viewer=user)


# ---------- Ratings ----------


@app.put("/destinations/{destination_id}/rating", response_model=RatingSummary)
def rate_destination(destination_id: str, payload: RatingRequest, user: str = Depends(get_current_user)):
    if payload.stars < 1 or payload.stars > 5:
        raise HTTPException(status_code=400, detail="stars must be between 1 and 5")
    dest = crud.get_destination(destination_id)
    if not dest or not crud.is_approved(dest):
        raise HTTPException(status_code=404, detail="Destination not found")
    result = crud.rate_destination(destination_id, user, payload.stars)
    events.publish("destination.rated", {"destination_id": destination_id, "user": user, "stars": payload.stars})
    return result


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
    if dest.get("submitted_by") != user and not await clients.is_admin(user):
        raise HTTPException(status_code=403, detail="Not allowed to modify this destination")

    ext = _IMAGE_EXTENSIONS.get((file.content_type or "").lower())
    if not ext:
        raise HTTPException(status_code=400, detail="Unsupported image type - use JPEG, PNG, WEBP or GIF")

    body = await file.read()
    if not body:
        raise HTTPException(status_code=400, detail="Empty file")
    if len(body) > _IMAGE_MAX_BYTES:
        raise HTTPException(status_code=400, detail="Image is larger than 5MB")

    old_url = dest.get("image_url") or ""
    slug = _slugify(dest.get("name") or "") or destination_id
    dest_path = _destinations_images_dir / f"{slug}{ext}"
    if dest_path.exists() and old_url != f"/static/destinations/{dest_path.name}":
        slug = f"{slug}-{destination_id}"
        dest_path = _destinations_images_dir / f"{slug}{ext}"

    if old_url.startswith("/static/destinations/"):
        stale = _destinations_images_dir / Path(old_url).name
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
def admin_update_destination(destination_id: str, payload: DestinationUpdate, admin: str = Depends(require_admin)):
    changes = {k: v for k, v in payload.dict().items() if v is not None}
    if changes.get("status") and changes["status"] not in (crud.APPROVED, crud.PENDING, crud.REJECTED):
        raise HTTPException(status_code=400, detail="Invalid status")
    updated = crud.update_destination(destination_id, changes)
    if not updated:
        raise HTTPException(status_code=404, detail="Destination not found")
    # Only the submitter cares, and only for a real moderation decision -
    # not every admin edit (a typo fix to an already-approved listing
    # shouldn't re-notify anyone).
    new_status = changes.get("status")
    if new_status in (crud.APPROVED, crud.REJECTED) and updated.get("submitted_by"):
        events.publish(
            f"destination.{new_status}",
            {
                "destination_id": updated["id"],
                "name": updated["name"],
                "submitted_by": updated["submitted_by"],
            },
        )
    return updated


@app.post("/admin/destinations", response_model=Destination)
def admin_create_destination(payload: DestinationSubmit, admin: str = Depends(require_admin)):
    name = (payload.name or "").strip()
    if not name:
        raise HTTPException(status_code=400, detail="Destination name is required")
    body = payload.dict()
    body["name"] = name
    created = crud.submit_destination(body, admin)
    return crud.update_destination(created["id"], {"status": crud.APPROVED})


@app.delete("/admin/destinations/{destination_id}")
def admin_delete_destination(destination_id: str, admin: str = Depends(require_admin)):
    if not crud.delete_destination(destination_id):
        raise HTTPException(status_code=404, detail="Destination not found")
    return {"deleted": destination_id}


# ---------- Comments ----------


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


@app.patch("/comments/{comment_id}", response_model=Comment)
def edit_comment(comment_id: str, payload: CommentUpdate, user: str = Depends(get_current_user)):
    text = payload.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Comment text is required")
    if len(text) > _COMMENT_MAX_CHARS:
        raise HTTPException(status_code=400, detail=f"Comment must be under {_COMMENT_MAX_CHARS} characters")
    try:
        updated = crud.update_comment(comment_id, user, text)
    except crud.CommentNotOwnedError:
        raise HTTPException(status_code=403, detail="You can only edit your own comment")
    except crud.CommentEditWindowExpiredError:
        raise HTTPException(status_code=403, detail="Comments can only be edited within 5 minutes of posting")
    if updated is None:
        raise HTTPException(status_code=404, detail="Comment not found")
    return updated


@app.delete("/comments/{comment_id}")
def delete_comment(comment_id: str, user: str = Depends(get_current_user)):
    try:
        deleted = crud.delete_comment(comment_id, user)
    except crud.CommentNotOwnedError:
        raise HTTPException(status_code=403, detail="You can only delete your own comment")
    except crud.CommentEditWindowExpiredError:
        raise HTTPException(status_code=403, detail="Comments can only be deleted within 5 minutes of posting")
    except crud.CommentHasRepliesError:
        raise HTTPException(status_code=409, detail="Can't delete a comment that already has replies")
    if not deleted:
        raise HTTPException(status_code=404, detail="Comment not found")
    return {"deleted": comment_id}


# ---------- Recommendations (the sync inter-service calls happen here) ----------


@app.get("/recommendations", response_model=list[Destination])
async def recommendations(user: str = Depends(get_current_user)):
    interests = await clients.get_user_interests(user)
    itineraries = await clients.get_itineraries_for(user)
    visited = {did for itin in itineraries for did in itin.get("destinations", [])}
    return crud.recommendations_for(interests, visited_destination_ids=visited, viewer=user)


# ---------- AI ----------


def _ai_error_response(exc: Exception):
    if isinstance(exc, ai.AiNotConfiguredError):
        return HTTPException(status_code=503, detail="AI assistant is not configured")
    return HTTPException(status_code=502, detail="AI assistant is temporarily unavailable")


@app.post("/ai/chat", response_model=ChatResponse)
async def ai_chat(payload: ChatRequest, user: str = Depends(get_current_user)):
    if not payload.messages:
        raise HTTPException(status_code=400, detail="messages must not be empty")
    interests = await clients.get_user_interests(user)
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

    # A cached explanation was only ever generated in one language - skip
    # it whenever a specific language is requested, rather than handing
    # back a stale-language answer just because it happened to be cached.
    cached = dest.get("ai_explanation")
    if cached and not language_code:
        return {"reply": cached}

    try:
        reply = await ai.explain_destination(dest, language_code=language_code)
    except (ai.AiNotConfiguredError, ai.AiRequestError) as exc:
        raise _ai_error_response(exc)
    if not language_code:
        crud.set_destination_ai_explanation(destination_id, reply)
    return {"reply": reply}


# ---------- Routing ----------


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
    except routing.RoutingNoRouteFoundError:
        raise HTTPException(status_code=422, detail="No route could be found between these points")
    except routing.RoutingRequestError:
        raise HTTPException(status_code=502, detail="Routing service is temporarily unavailable")
    return result


# ---------- Amenities ----------


@app.get("/amenities", response_model=list[Amenity])
async def get_amenities(
    lat: float,
    lon: float,
    radius: float = amenities.DEFAULT_RADIUS_METERS,
    categories: str | None = None,
    user: str | None = Depends(get_optional_user),
):
    radius = min(max(radius, 100.0), amenities.MAX_RADIUS_METERS)
    requested = set(categories.split(",")) if categories else amenities.ALLOWED_CATEGORIES
    selected = sorted(requested & amenities.ALLOWED_CATEGORIES)
    if not selected:
        return []
    try:
        return await amenities.get_amenities(lat, lon, radius, selected)
    except amenities.AmenitiesRequestError:
        # Best-effort map overlay, not a blocking feature - the failure is
        # already logged inside amenities.py, so the map just shows nothing
        # rather than an error state.
        return []


# ---------- Internal (service-to-service only, never through the Gateway) ----------


@app.get("/internal/destinations", response_model=list[Destination])
def internal_get_destinations(ids: str, viewer: str | None = None, _=Depends(require_internal)):
    """Lets user_service hydrate a viewer's favorite_ids into full
    Destination objects (see user_service/app/clients.py)."""
    id_list = [i for i in ids.split(",") if i]
    return crud.get_destinations_by_ids(id_list, viewer=viewer)


@app.get("/internal/destinations/count")
def internal_destination_count(_=Depends(require_internal)):
    from .data import read_data

    return {"count": len(read_data().get("destinations", []))}
