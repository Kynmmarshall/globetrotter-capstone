from pathlib import Path

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from . import crud
from .schemas import UserCreate, Token, Itinerary, Destination, ItineraryCreate
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


@app.post("/register", response_model=Token)
def register(u: UserCreate):
    user = crud.register_user(u.username, u.password, u.email)
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


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/destinations", response_model=list[Destination])
def destinations(q: str = None):
    return crud.search_destinations(q)


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
