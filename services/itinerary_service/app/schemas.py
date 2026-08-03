from pydantic import BaseModel
from typing import Optional, List


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


class ItineraryUpdate(BaseModel):
    title: Optional[str] = None
    destinations: Optional[List[str]] = None
    schedule: Optional[List[ScheduleItem]] = None
    start_date: Optional[str] = None
    end_date: Optional[str] = None


class ShareResponse(BaseModel):
    share_token: str


class SharedDestination(BaseModel):
    """A trimmed-down, public-safe view of a destination for the shared
    itinerary page - no viewer-specific fields (a rating the owner gave,
    favorite status, etc), since whoever opens the link may not even have
    a trip_io account.
    """
    id: str
    name: str
    image_url: Optional[str] = None
    location: Optional[str] = None
    lat: Optional[float] = None
    lon: Optional[float] = None


class SharedItinerary(BaseModel):
    title: str
    destinations: List[SharedDestination]
