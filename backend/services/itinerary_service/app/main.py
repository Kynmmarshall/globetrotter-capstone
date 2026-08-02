from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware

from . import crud, events
from .schemas import Itinerary, ItineraryCreate
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


@app.delete("/itineraries/{itinerary_id}")
def delete_itinerary(itinerary_id: str, user: str = Depends(get_current_user)):
    if not crud.delete_itinerary(itinerary_id, user):
        raise HTTPException(status_code=404, detail="Itinerary not found")
    return {"deleted": itinerary_id}


# ---------- Internal (service-to-service only, never through the Gateway) ----------


@app.get("/internal/itineraries/{username}", response_model=list[Itinerary])
def internal_get_itineraries(username: str, _=Depends(require_internal)):
    """Lets recommendation_service read a user's trip history when
    personalizing recommendations - the sync REST call in the direction the
    slide's own example describes (Recommendation Service -> Itinerary
    Service)."""
    return crud.get_itineraries_for(username)
