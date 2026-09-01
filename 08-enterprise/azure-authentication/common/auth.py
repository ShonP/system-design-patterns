"""Shared JWT validator - used by both api-a and api-b.

Validation steps (same as real Entra ID):
    1. Fetch the signing keys from JWKS (cached, re-fetched when an unknown
       ``kid`` shows up - that is what key rotation looks like from here).
    2. Verify RS256 signature, issuer, audience, expiry, not-before.
    3. Return decoded claims so handlers can enforce scopes / roles.

Two traps this file deliberately closes, because both bite real services:

*   **python-jose silently *skips* a claim that is missing.** ``_validate_aud``
    and ``_validate_exp`` both start with ``if "aud"/"exp" not in claims:
    return``. So a *validly signed* token with no ``aud`` and no ``exp`` sails
    straight through ``jwt.decode(..., audience=..., issuer=...)``. That turns
    "audience-scoped, short-lived" into "any audience, never expires". We force
    the claims to be present with the ``require_*`` options below. Whatever JWT
    library you use in production, check this behaviour yourself.
*   **``algorithms`` must be pinned.** Passing the list stops ``alg: none`` and
    RS256/HS256 confusion attacks. Never derive the algorithm from the token's
    own header.
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

_jwks_cache: dict[str, Any] = {"fetched_at": 0.0, "keys": {}}
_JWKS_TTL_SECONDS = 300
# Floor between forced re-fetches, so a flood of tokens carrying a bogus `kid`
# cannot turn this API into a request amplifier pointed at the identity provider.
_JWKS_MIN_REFETCH_SECONDS = 10

# Clock skew we tolerate on exp / nbf. Entra itself allows ~5 minutes; a minute
# is plenty between containers on one host and keeps the demo honest.
_CLOCK_SKEW_SECONDS = 60

# python-jose skips a claim it cannot find. Require the ones that carry the
# security properties we are claiming to enforce.
_CLAIM_OPTIONS = {
    "require_aud": True,
    "require_exp": True,
    "require_iat": True,
    "require_nbf": True,
    "require_iss": True,
    "require_sub": True,
    "leeway": _CLOCK_SKEW_SECONDS,
}


def _fetch_jwks() -> dict[str, dict]:
    resp = httpx.get(JWKS_URI, timeout=5.0)
    resp.raise_for_status()
    keys = {k["kid"]: k for k in resp.json()["keys"]}
    _jwks_cache.update(fetched_at=time.time(), keys=keys)
    return keys


def _get_jwks(force: bool = False) -> dict[str, dict]:
    age = time.time() - _jwks_cache["fetched_at"]
    if force:
        # Only honour a forced refresh if we have not just done one.
        return _fetch_jwks() if age >= _JWKS_MIN_REFETCH_SECONDS else _jwks_cache["keys"]
    if age < _JWKS_TTL_SECONDS and _jwks_cache["keys"]:
        return _jwks_cache["keys"]
    return _fetch_jwks()


def validate_token(raw: str) -> dict:
    try:
        header = jwt.get_unverified_header(raw)
    except Exception as e:
        raise HTTPException(401, f"malformed token: {e}")

    # `kid` is untrusted at this point - it is only a lookup key into JWKS.
    # A token whose kid is absent from our cache may simply predate/postdate a
    # key roll, so re-fetch once before giving up. Without this, rotation causes
    # up to _JWKS_TTL_SECONDS of 401s.
    kid = header.get("kid")
    keys = _get_jwks()
    key = keys.get(kid)
    if not key:
        keys = _get_jwks(force=True)
        key = keys.get(kid)
    if not key:
        raise HTTPException(401, "unknown signing key (kid)")

    try:
        return jwt.decode(
            raw,
            key,
            algorithms=["RS256"],          # pinned: no alg confusion, no `alg: none`
            audience=EXPECTED_AUDIENCE,    # is this token *for us*?
            issuer=EXPECTED_ISSUER,        # is it from *our* tenant?
            options=_CLAIM_OPTIONS,        # exp/nbf/aud/iss/sub must be present
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
    """Token has no user identity - app is calling on its own behalf.

    Note the direction of the test: we treat a token as app-only only when it
    carries *neither* a user principal *nor* delegated scopes. Getting this
    backwards (defaulting to app-only) would let a scope-less token skip the
    delegated check entirely. Real Entra v2 also emits `idtyp: "app"` on
    app-only tokens; prefer that claim when it is available to you.
    """
    return "upn" not in claims and not claims.get("scp")
