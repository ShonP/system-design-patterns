"""
API-A - the middle-tier web API.

Accepts an incoming user token, then calls the downstream API-B in two modes:

    GET /proxy/files        - On-Behalf-Of (delegated, user-scoped)
    GET /proxy/files/admin  - Client credentials (app-only, app-role)

This is exactly the pattern Entra ID recommends for multi-tier web APIs:
    https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-on-behalf-of-flow
"""
import os

import httpx
from fastapi import FastAPI, Header, HTTPException

from common.auth import validate_token

AUTHORITY_INTERNAL = os.environ["AUTHORITY_INTERNAL"]
API_A_CLIENT_ID = os.environ["API_A_CLIENT_ID"]
API_A_CLIENT_SECRET = os.environ["API_A_CLIENT_SECRET"]
API_B_BASE_URL = os.environ["API_B_BASE_URL"]
API_B_IDENTIFIER_URI = os.environ["API_B_IDENTIFIER_URI"]
TENANT_ID = os.environ["TENANT_ID"]

TOKEN_URL = f"{AUTHORITY_INTERNAL}/{TENANT_ID}/oauth2/v2.0/token"

app = FastAPI(title="API-A (middle tier)")


@app.get("/health")
def health():
    return {"status": "ok", "service": "api-a"}


def _require_bearer(authorization: str | None) -> tuple[str, dict]:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(401, "missing Bearer token")
    raw = authorization.split(" ", 1)[1]
    return raw, validate_token(raw)


def _exchange_obo(user_assertion: str, downstream_scope: str) -> str:
    """Swap the user's token for one that targets API-B (On-Behalf-Of)."""
    data = {
        "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "client_id": API_A_CLIENT_ID,
        "client_secret": API_A_CLIENT_SECRET,
        "assertion": user_assertion,
        "scope": downstream_scope,
        "requested_token_use": "on_behalf_of",
    }
    resp = httpx.post(TOKEN_URL, data=data, timeout=5.0)
    if resp.status_code != 200:
        raise HTTPException(502, f"OBO failed: {resp.text}")
    return resp.json()["access_token"]


def _client_credentials(resource_uri: str) -> str:
    """Get an app-only token for API-A itself to call downstream."""
    data = {
        "grant_type": "client_credentials",
        "client_id": API_A_CLIENT_ID,
        "client_secret": API_A_CLIENT_SECRET,
        "scope": f"{resource_uri}/.default",
    }
    resp = httpx.post(TOKEN_URL, data=data, timeout=5.0)
    if resp.status_code != 200:
        raise HTTPException(502, f"client credentials failed: {resp.text}")
    return resp.json()["access_token"]


@app.get("/proxy/files")
def proxy_user_files(authorization: str | None = Header(None)):
    """Forward the *user's* identity to API-B using On-Behalf-Of."""
    raw_user_token, claims = _require_bearer(authorization)
    downstream_token = _exchange_obo(
        user_assertion=raw_user_token,
        downstream_scope=f"{API_B_IDENTIFIER_URI}/Files.Read",
    )
    r = httpx.get(
        f"{API_B_BASE_URL}/files",
        headers={"Authorization": f"Bearer {downstream_token}"},
        timeout=5.0,
    )
    return {"api_a_saw_user": claims.get("upn"), "api_b_response": r.json()}


@app.get("/proxy/files/admin")
def proxy_admin_files(authorization: str | None = Header(None)):
    """Call API-B as API-A itself (ignore the user) using client credentials."""
    _, claims = _require_bearer(authorization)
    downstream_token = _client_credentials(API_B_IDENTIFIER_URI)
    r = httpx.get(
        f"{API_B_BASE_URL}/files",
        headers={"Authorization": f"Bearer {downstream_token}"},
        timeout=5.0,
    )
    return {
        "api_a_caller": claims.get("upn") or claims.get("azp"),
        "api_b_response": r.json(),
    }
