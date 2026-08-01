"""Verifies Supabase Auth JWTs.

Modern Supabase projects sign access tokens with an asymmetric key (ES256) published at the
project's JWKS endpoint — no shared secret involved, verification just needs the public key.
Older projects (or ones that haven't rotated to the new signing keys) still use a legacy HS256
shared secret instead, so that path is kept as a fallback for compatibility.
"""
import asyncio
from functools import lru_cache
from typing import Any

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import PyJWKClient

from app.core.config import settings

_security = HTTPBearer(auto_error=True)


@lru_cache
def _get_jwks_client() -> PyJWKClient:
    return PyJWKClient(f"{settings.SUPABASE_URL}/auth/v1/.well-known/jwks.json")


def _unauthorized(exc: Exception) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=f"Invalid or expired authentication token: {exc}",
        headers={"WWW-Authenticate": "Bearer"},
    )


async def verify_supabase_token(
    credentials: HTTPAuthorizationCredentials = Depends(_security),
) -> dict[str, Any]:
    """FastAPI dependency: verifies the bearer access token issued by Supabase Auth on the client."""
    token = credentials.credentials

    if settings.SUPABASE_URL:
        try:
            signing_key = await asyncio.to_thread(_get_jwks_client().get_signing_key_from_jwt, token)
            return jwt.decode(token, signing_key.key, algorithms=["ES256", "RS256"], audience="authenticated")
        except jwt.PyJWKClientError:
            pass  # no matching key published (e.g. project still on legacy HS256) — fall through
        except jwt.InvalidTokenError as exc:
            raise _unauthorized(exc) from exc

    if not settings.SUPABASE_JWT_SECRET:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not verify token: no matching JWKS key and SUPABASE_JWT_SECRET is not configured.",
        )
    try:
        return jwt.decode(token, settings.SUPABASE_JWT_SECRET, algorithms=["HS256"], audience="authenticated")
    except jwt.PyJWTError as exc:
        raise _unauthorized(exc) from exc
