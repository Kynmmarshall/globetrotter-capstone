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
    image_url: Optional[str] = None
    description: Optional[str] = None
    location: Optional[str] = None

class ScheduleItem(BaseModel):
    destination_id: str
    start: str
    end: str

class Itinerary(BaseModel):
    id: Optional[str]
    user: str
    title: str
    destinations: List[str]
    schedule: Optional[List[ScheduleItem]] = None

class ItineraryCreate(BaseModel):
    title: str
    destinations: List[str]
    schedule: Optional[List[ScheduleItem]] = None
