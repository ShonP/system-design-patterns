"""Shared JWT validator - used by both api-a and api-b.

Validation steps (same as real Entra ID):
    1. Fetch the signing keys from JWKS (cached).
    2. Verify RS256 signature, issuer, audience, expiry.
    3. Return decoded claims so handlers can enforce scopes / roles.
"""
import os
import time
from typing import Any

import httpx
from fastapi import Header, HTTPException
from jose import jwt

JWKS_URI = os.environ["JWKS_URI"]
EXPECTED_ISSUER = os.environ["EXPECTED_ISSUER"]
EXPECTED_AUDIENCE = os.environ["EXPECTED_AUDIENCE"]

_jwks_cache: dict[str, Any] = {"fetched_at": 0, "keys": {}}
_JWKS_TTL_SECONDS = 300


def _get_jwks() -> dict[str, dict]:
    if time.time() - _jwks_cache["fetched_at"] < _JWKS_TTL_SECONDS and _jwks_cache["keys"]:
        return _jwks_cache["keys"]
    resp = httpx.get(JWKS_URI, timeout=5.0)
    resp.raise_for_status()
    keys = {k["kid"]: k for k in resp.json()["keys"]}
    _jwks_cache.update(fetched_at=time.time(), keys=keys)
    return keys


def validate_token(raw: str) -> dict:
    try:
        header = jwt.get_unverified_header(raw)
    except Exception as e:
        raise HTTPException(401, f"malformed token: {e}")

    keys = _get_jwks()
    key = keys.get(header.get("kid"))
    if not key:
        raise HTTPException(401, "unknown signing key (kid)")

    try:
        return jwt.decode(
            raw,
            key,
            algorithms=["RS256"],
            audience=EXPECTED_AUDIENCE,
            issuer=EXPECTED_ISSUER,
        )
    except Exception as e:
        raise HTTPException(401, f"token validation failed: {e}")


def bearer_claims(authorization: str | None = Header(None)) -> dict:
    """FastAPI dependency: extract + validate Bearer token, return claims."""
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(401, "missing Bearer token")
    return validate_token(authorization.split(" ", 1)[1])


def require_scope(claims: dict, scope: str) -> None:
    """Delegated permission check (user is signed in)."""
    scopes = (claims.get("scp") or "").split()
    if scope not in scopes:
        raise HTTPException(403, f"missing delegated scope: {scope}")


def require_app_role(claims: dict, role: str) -> None:
    """Application permission check (app-only token, no user)."""
    if role not in (claims.get("roles") or []):
        raise HTTPException(403, f"missing app role: {role}")


def is_app_only(claims: dict) -> bool:
    """Token has no user identity - app is calling on its own behalf."""
    return "upn" not in claims and not claims.get("scp")
