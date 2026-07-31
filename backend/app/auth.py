import os
import time
from typing import Optional
import jwt
from passlib.context import CryptContext
from fastapi import HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
_secret = os.getenv("JWT_SECRET", "dev-secret-change-me")
_algo = "HS256"

def _truncate_password(password: str, max_bytes: int = 72) -> str:
    b = password.encode("utf-8")
    if len(b) <= max_bytes:
        return password
    truncated = b[:max_bytes]
    return truncated.decode("utf-8", errors="ignore")

def hash_password(password: str) -> str:
    safe = _truncate_password(password)
    return pwd_context.hash(safe)

def verify_password(plain: str, hashed: str) -> bool:
    safe = _truncate_password(plain)
    return pwd_context.verify(safe, hashed)

_ONE_WEEK_SECONDS = 7 * 24 * 3600

def create_access_token(sub: str, expires: int = _ONE_WEEK_SECONDS) -> str:
    now = int(time.time())
    payload = {"sub": sub, "iat": now, "exp": now + expires}
    return jwt.encode(payload, _secret, algorithm=_algo)

def decode_token(token: str) -> Optional[dict]:
    try:
        return jwt.decode(token, _secret, algorithms=[_algo])
    except jwt.PyJWTError:
        return None

security = HTTPBearer()
# auto_error=False so endpoints that work for both signed-in and anonymous
# callers (e.g. /destinations, which the public website also fetches) can
# personalise their response without requiring a token.
optional_security = HTTPBearer(auto_error=False)

def get_current_user(creds: HTTPAuthorizationCredentials = Depends(security)):
    payload = decode_token(creds.credentials)
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid token")
    return payload.get("sub")

def get_optional_user(
    creds: HTTPAuthorizationCredentials = Depends(optional_security),
) -> Optional[str]:
    if not creds:
        return None
    payload = decode_token(creds.credentials)
    return payload.get("sub") if payload else None

def is_admin(username: str) -> bool:
    # Reads .data directly rather than going through crud, which imports
    # this module - a crud import here would be circular.
    from .data import read_data

    for u in read_data().get("users", []):
        if u.get("username") == username:
            return u.get("role") == "admin"
    return False

def require_admin(user: str = Depends(get_current_user)) -> str:
    """Like get_current_user, but 403s anyone whose account isn't flagged
    role="admin" in data.json. Promote an account by setting that field."""
    if not is_admin(user):
        raise HTTPException(status_code=403, detail="Admin access required")
    return user
