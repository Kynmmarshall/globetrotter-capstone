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
