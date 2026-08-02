"""Same JWT scheme as the Phase 1 monolith (app/auth.py) - deliberately
duplicated rather than imported from a shared package, so this service's
Docker image only ever needs its own directory as build context and can be
built/deployed with zero knowledge of its siblings. All services share the
same JWT_SECRET env var, which is what lets a token minted here be verified
independently by the other two without a network call back to this one.
"""
import os
import time
from typing import Optional

import jwt
from passlib.context import CryptContext
from fastapi import HTTPException, Depends, Header
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
_secret = os.getenv("JWT_SECRET", "dev-secret-change-me")
_algo = "HS256"

# Separate from JWT_SECRET - authenticates service-to-service calls under
# /internal/*, which never go through end-user JWTs at all. Never exposed
# through the Gateway.
INTERNAL_SERVICE_TOKEN = os.getenv("INTERNAL_SERVICE_TOKEN", "dev-internal-token-change-me")


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


def require_internal(x_internal_token: str = Header(default=None)) -> None:
    """Gate for /internal/* endpoints - checked instead of a user JWT, since
    these are only ever called by the other services, never by the Gateway
    on a client's behalf."""
    if x_internal_token != INTERNAL_SERVICE_TOKEN:
        raise HTTPException(status_code=403, detail="Not an authorized internal caller")
