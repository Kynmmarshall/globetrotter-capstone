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
    avatar_url: Optional[str] = None
    favorite_ids: Optional[List[str]] = []
    role: Optional[str] = "user"  # "user" | "admin"

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
    lat: Optional[float] = None
    lon: Optional[float] = None
    nearby: Optional[List[NearbyPlace]] = None
    opening_hours: Optional[str] = None
    entry_fee: Optional[str] = None
    tips: Optional[str] = None
    # Moderation: "approved" destinations are the public catalog; "pending"
    # ones are user submissions awaiting review; "rejected" ones are kept
    # (not deleted) so a submitter can still see what happened to theirs.
    status: Optional[str] = "approved"
    submitted_by: Optional[str] = None
    # Aggregated from the ratings store - never stored on the destination
    # record itself, so they can't drift out of sync with the raw ratings.
    rating_average: Optional[float] = None
    rating_count: Optional[int] = 0
    # The requesting user's own 1-5 star rating, if they've left one.
    user_rating: Optional[int] = None

class DestinationSubmit(BaseModel):
    """What a regular user may supply when proposing a new destination.
    Deliberately excludes id/status/submitted_by - the server owns those."""
    name: str
    description: Optional[str] = None
    location: Optional[str] = None
    tags: Optional[List[str]] = []
    country: Optional[str] = "Cameroon"
    image_url: Optional[str] = None
    opening_hours: Optional[str] = None
    entry_fee: Optional[str] = None
    tips: Optional[str] = None

class DestinationUpdate(BaseModel):
    """Admin edit payload - every field optional, only what's sent changes."""
    name: Optional[str] = None
    description: Optional[str] = None
    location: Optional[str] = None
    lat: Optional[float] = None
    lon: Optional[float] = None
    tags: Optional[List[str]] = None
    country: Optional[str] = None
    image_url: Optional[str] = None
    opening_hours: Optional[str] = None
    entry_fee: Optional[str] = None
    tips: Optional[str] = None
    status: Optional[str] = None

class RatingRequest(BaseModel):
    stars: int  # 1-5

class RatingSummary(BaseModel):
    destination_id: str
    rating_average: Optional[float] = None
    rating_count: int = 0
    user_rating: Optional[int] = None

class RouteWaypoint(BaseModel):
    lat: float
    lon: float

class RouteRequest(BaseModel):
    waypoints: List[RouteWaypoint]
    profile: str = "driving-car"  # driving-car | foot-walking | cycling-regular

class RouteResponse(BaseModel):
    geometry: List[RouteWaypoint]
    distance_meters: float
    duration_seconds: float

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

class GoogleAuthRequest(BaseModel):
    id_token: str

class ChatMessage(BaseModel):
    role: str  # "user" | "assistant"
    content: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]

class ChatResponse(BaseModel):
    reply: str

class CommentCreate(BaseModel):
    text: str
    parent_id: Optional[str] = None

class VoteRequest(BaseModel):
    direction: str  # "up" | "down" | "none"

class Comment(BaseModel):
    id: str
    destination_id: str
    parent_id: Optional[str] = None
    username: str
    text: str
    created_at: str
    score: int
    # The requesting viewer's own vote on this comment - "up", "down", or
    # null. Computed per-request, not stored verbatim on the comment.
    user_vote: Optional[str] = None
    replies: List["Comment"] = []

Comment.model_rebuild()
