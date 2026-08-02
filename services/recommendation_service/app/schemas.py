from pydantic import BaseModel
from typing import Optional, List


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
    status: Optional[str] = "approved"
    submitted_by: Optional[str] = None
    rating_average: Optional[float] = None
    rating_count: Optional[int] = 0
    user_rating: Optional[int] = None
    comment_count: Optional[int] = 0


class DestinationSubmit(BaseModel):
    name: str
    description: Optional[str] = None
    location: Optional[str] = None
    lat: Optional[float] = None
    lon: Optional[float] = None
    tags: Optional[List[str]] = []
    country: Optional[str] = "Cameroon"
    image_url: Optional[str] = None
    opening_hours: Optional[str] = None
    entry_fee: Optional[str] = None
    tips: Optional[str] = None


class DestinationUpdate(BaseModel):
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
    stars: int


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
    profile: str = "driving-car"


class RouteResponse(BaseModel):
    geometry: List[RouteWaypoint]
    distance_meters: float
    duration_seconds: float


class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    messages: List[ChatMessage]


class ChatResponse(BaseModel):
    reply: str


class CommentCreate(BaseModel):
    text: str
    parent_id: Optional[str] = None


class CommentUpdate(BaseModel):
    text: str


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
    user_vote: Optional[str] = None
    replies: List["Comment"] = []


Comment.model_rebuild()
