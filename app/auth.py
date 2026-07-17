import time
from typing import Optional
import jwt
from passlib.context import CryptContext
from fastapi import HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
_secret = "dev-secret-change-me"
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

def create_access_token(sub: str, expires: int = 3600) -> str:
    now = int(time.time())
    payload = {"sub": sub, "iat": now, "exp": now + expires}
    return jwt.encode(payload, _secret, algorithm=_algo)

def decode_token(token: str) -> Optional[dict]:
    try:
        return jwt.decode(token, _secret, algorithms=[_algo])
    except jwt.PyJWTError:
        return None

security = HTTPBearer()

def get_current_user(creds: HTTPAuthorizationCredentials = Depends(security)):
    payload = decode_token(creds.credentials)
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid token")
    return payload.get("sub")
