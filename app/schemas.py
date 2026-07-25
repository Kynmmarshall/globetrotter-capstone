from pydantic import BaseModel
from typing import Optional, List

class UserCreate(BaseModel):
    username: str
    password: str
    email: Optional[str] = None
    interests: Optional[List[str]] = None

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class UserProfile(BaseModel):
    username: str
    email: Optional[str] = None
    interests: Optional[List[str]] = []

class InterestsUpdate(BaseModel):
    interests: List[str]

class NearbyPlace(BaseModel):
    name: str
    category: str  # "hotel" | "restaurant"
    description: Optional[str] = None
    tags: Optional[List[str]] = []
    location: Optional[str] = None

class Destination(BaseModel):
    id: str
    name: str
    country: Optional[str]
    tags: Optional[List[str]] = []
    image_url: Optional[str] = None
    description: Optional[str] = None
    location: Optional[str] = None
    nearby: Optional[List[NearbyPlace]] = None
    opening_hours: Optional[str] = None
    entry_fee: Optional[str] = None
    tips: Optional[str] = None

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
    start_date: Optional[str] = None
    end_date: Optional[str] = None

class ItineraryCreate(BaseModel):
    title: str
    destinations: List[str]
    schedule: Optional[List[ScheduleItem]] = None
    start_date: Optional[str] = None
    end_date: Optional[str] = None
