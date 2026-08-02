"""Verifies Google Sign-In ID tokens via Google's tokeninfo endpoint - a
single GET request, same lightweight-HTTP-over-SDK approach the monolith
used. Google's endpoint already validates the token's signature, issuer and
expiry; we only need to check the audience matches our own OAuth client.
"""
import logging
import os

import httpx

logger = logging.getLogger("trip_io.user_service.google_auth")

GOOGLE_OAUTH_CLIENT_ID = os.getenv("GOOGLE_OAUTH_CLIENT_ID")
_TOKENINFO_URL = "https://oauth2.googleapis.com/tokeninfo"
_VALID_ISSUERS = ("accounts.google.com", "https://accounts.google.com")


class GoogleTokenError(Exception):
    pass


async def verify_id_token(id_token: str) -> dict:
    if not GOOGLE_OAUTH_CLIENT_ID:
        raise GoogleTokenError("GOOGLE_OAUTH_CLIENT_ID is not set")

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(_TOKENINFO_URL, params={"id_token": id_token})
    except httpx.HTTPError as exc:
        logger.warning("Google tokeninfo request failed: %s", exc)
        raise GoogleTokenError("Could not reach Google to verify token") from exc

    if resp.status_code != 200:
        raise GoogleTokenError("Invalid or expired Google ID token")

    claims = resp.json()
    if claims.get("aud") != GOOGLE_OAUTH_CLIENT_ID:
        raise GoogleTokenError("Token was not issued for this app")
    if claims.get("iss") not in _VALID_ISSUERS:
        raise GoogleTokenError("Unexpected token issuer")
    if claims.get("email_verified") not in ("true", True):
        raise GoogleTokenError("Google account email is not verified")

    return claims
