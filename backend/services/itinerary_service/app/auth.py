"""Same JWT scheme as user_service/app/auth.py - see that file's docstring
for why this is duplicated per-service rather than shared."""
import os
import time
from typing import Optional

import jwt
from fastapi import HTTPException, Depends, Header
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

_secret = os.getenv("JWT_SECRET", "dev-secret-change-me")
_algo = "HS256"

INTERNAL_SERVICE_TOKEN = os.getenv("INTERNAL_SERVICE_TOKEN", "dev-internal-token-change-me")

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
    if x_internal_token != INTERNAL_SERVICE_TOKEN:
        raise HTTPException(status_code=403, detail="Not an authorized internal caller")
