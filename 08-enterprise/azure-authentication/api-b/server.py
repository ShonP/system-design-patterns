"""
API-B - the downstream resource API.

Protects /files/* with JWT bearer auth. Demonstrates two permission models:
    - Delegated (scope "Files.Read") - a user is signed in; enforced via require_scope
    - Application (app role "Files.Read.All") - app-only token; enforced via require_app_role

Both paths return the same shape so you can see in notebooks how the claims differ.
"""
from fastapi import Depends, FastAPI

from common.auth import (
    bearer_claims,
    is_app_only,
    require_app_role,
    require_scope,
)

app = FastAPI(title="API-B (downstream resource)")

_FAKE_FILES = [
    {"id": "f1", "owner": "alice@contoso.com", "name": "design-doc.md"},
    {"id": "f2", "owner": "alice@contoso.com", "name": "budget.xlsx"},
    {"id": "f3", "owner": "bob@contoso.com",   "name": "plan.pdf"},
]


@app.get("/health")
def health():
    return {"status": "ok", "service": "api-b"}


@app.get("/files")
def list_files(claims: dict = Depends(bearer_claims)):
    """
    Two ways a caller can reach this endpoint:

    1. *App-only* (client credentials from a daemon or managed identity).
       Token carries `roles: ["Files.Read.All"]` - we return everything.

    2. *Delegated* (user signed in, possibly via OBO from api-a).
       Token carries `scp: "Files.Read"` + `upn` - we return only that user's files.
    """
    if is_app_only(claims):
        require_app_role(claims, "Files.Read.All")
        return {
            "mode": "app-only",
            "caller": claims.get("azp"),
            "files": _FAKE_FILES,
        }

    require_scope(claims, "Files.Read")
    user_files = [f for f in _FAKE_FILES if f["owner"] == claims.get("upn")]
    return {
        "mode": "delegated",
        "user": claims.get("upn"),
        "caller_app": claims.get("azp"),
        "files": user_files,
    }


@app.get("/whoami")
def whoami(claims: dict = Depends(bearer_claims)):
    """Return a safe subset of the token claims - useful for notebooks."""
    keep = ("aud", "iss", "azp", "sub", "oid", "upn", "name", "scp", "roles", "tid", "exp")
    return {k: claims.get(k) for k in keep if k in claims}
