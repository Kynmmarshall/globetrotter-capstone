from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware

from . import clients, crud, events
from .schemas import (
    Itinerary,
    ItineraryCreate,
    ItineraryUpdate,
    ShareResponse,
    SharedItinerary,
)
from .auth import get_current_user, require_internal

app = FastAPI(title="trip_io Itinerary Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok", "service": "itinerary_service"}


@app.post("/itineraries", response_model=Itinerary)
def create_itinerary(itin: ItineraryCreate, user: str = Depends(get_current_user)):
    data = itin.dict()
    data["user"] = user
    created = crud.create_itinerary(data)
    events.publish(
        "itinerary.created",
        {"user": user, "id": created["id"], "destinations": created["destinations"]},
    )
    return created


@app.get("/itineraries", response_model=list[Itinerary])
def list_itineraries(user: str = Depends(get_current_user)):
    return crud.get_itineraries_for(user)


@app.patch("/itineraries/{itinerary_id}", response_model=Itinerary)
def update_itinerary(
    itinerary_id: str, updates: ItineraryUpdate, user: str = Depends(get_current_user)
):
    updated = crud.update_itinerary(
        itinerary_id, user, updates.dict(exclude_unset=True)
    )
    if updated is None:
        raise HTTPException(status_code=404, detail="Itinerary not found")
    events.publish(
        "itinerary.updated",
        {"user": user, "id": itinerary_id, "destinations": updated["destinations"]},
    )
    return updated


@app.delete("/itineraries/{itinerary_id}")
def delete_itinerary(itinerary_id: str, user: str = Depends(get_current_user)):
    if not crud.delete_itinerary(itinerary_id, user):
        raise HTTPException(status_code=404, detail="Itinerary not found")
    return {"deleted": itinerary_id}


@app.post("/itineraries/{itinerary_id}/share", response_model=ShareResponse)
def share_itinerary(itinerary_id: str, user: str = Depends(get_current_user)):
    token = crud.get_or_create_share_token(itinerary_id, user)
    if token is None:
        raise HTTPException(status_code=404, detail="Itinerary not found")
    return {"share_token": token}


@app.delete("/itineraries/{itinerary_id}/share")
def unshare_itinerary(itinerary_id: str, user: str = Depends(get_current_user)):
    crud.revoke_share_token(itinerary_id, user)
    return {"revoked": itinerary_id}


@app.get("/shared/itineraries/{token}", response_model=SharedItinerary)
async def get_shared_itinerary(token: str):
    itinerary = crud.get_itinerary_by_share_token(token)
    if itinerary is None:
        raise HTTPException(status_code=404, detail="Shared itinerary not found")
    destinations = await clients.get_destinations_by_ids(itinerary.get("destinations", []))
    # Preserve the itinerary's own stop order, not whatever order the
    # hydration call happens to return them in.
    by_id = {d["id"]: d for d in destinations}
    ordered = [
        by_id[d_id] for d_id in itinerary.get("destinations", []) if d_id in by_id
    ]
    return {"title": itinerary["title"], "destinations": ordered}


# ---------- Internal (service-to-service only, never through the Gateway) ----------


@app.get("/internal/itineraries/{username}", response_model=list[Itinerary])
def internal_get_itineraries(username: str, _=Depends(require_internal)):
    """Lets recommendation_service read a user's trip history when
    personalizing recommendations - the sync REST call in the direction the
    slide's own example describes (Recommendation Service -> Itinerary
    Service)."""
    return crud.get_itineraries_for(username)
