from pydantic import BaseModel
from typing import Optional, List

class UserCreate(BaseModel):
    username: str
    password: str
    email: Optional[str] = None

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class Destination(BaseModel):
    id: str
    name: str
    country: Optional[str]
    tags: Optional[List[str]] = []

class Itinerary(BaseModel):
    id: Optional[str]
    user: str
    title: str
    destinations: List[str]

class ItineraryCreate(BaseModel):
    title: str
    destinations: List[str]
