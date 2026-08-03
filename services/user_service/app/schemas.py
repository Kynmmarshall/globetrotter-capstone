from pydantic import BaseModel
from typing import Dict, Optional, List


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


class GoogleAuthRequest(BaseModel):
    id_token: str


class PasswordResetRequest(BaseModel):
    identifier: str  # username or email


class PasswordReset(BaseModel):
    identifier: str
    code: str
    new_password: str


class NearbyPlace(BaseModel):
    name: str
    category: str
    description: Optional[str] = None
    tags: Optional[List[str]] = []
    location: Optional[str] = None


class Destination(BaseModel):
    """Mirrors recommendation_service's Destination DTO - this service
    doesn't own destination data, it only ever relays what
    recommendation_service returns from GET /internal/destinations when
    hydrating a user's favorites, so the shape has to match field-for-field."""
    id: str
    name: str
    country: Optional[str] = None
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


class Notification(BaseModel):
    """title_key/body_key are Flutter ARB keys, not rendered text - see
    events_consumer.py for why this service never renders English itself."""
    id: str
    type: str  # "moderation" | "trip_reminder"
    title_key: str
    body_key: str
    body_args: Optional[Dict[str, str]] = {}
    destination_id: Optional[str] = None
    itinerary_id: Optional[str] = None
    created_at: str
    read: bool = False


class InternalUserProfile(BaseModel):
    """What /internal/users/{username} hands back to other services - a
    superset of the public UserProfile (adds is_admin explicitly, since
    only this service can see the raw role field)."""
    username: str
    interests: List[str] = []
    is_admin: bool = False
