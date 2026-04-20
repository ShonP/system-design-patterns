"""
Mock Microsoft Entra ID (Azure AD) v2.0 token endpoint.

Implements just enough of the OAuth2 / OIDC surface to teach:
    - client_credentials grant (service-to-service, app role claim)
    - password grant (ROPC - used here ONLY to get a user token for OBO demos,
      NEVER do this in production)
    - urn:ietf:params:oauth:grant-type:jwt-bearer (On-Behalf-Of)
    - JWKS + OpenID discovery so downstream APIs validate signatures normally

The tokens it issues are real, signed RS256 JWTs. The code that validates them
in api-a / api-b is exactly what you would run against real Entra ID - only
the issuer / JWKS URL would differ.
"""
import base64
import json
import time
import uuid
from pathlib import Path

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from fastapi import FastAPI, Form, HTTPException
from fastapi.responses import JSONResponse
from jose import jwk, jwt

TENANT = "contoso"
ISSUER = f"http://localhost:9100/{TENANT}/v2.0"
TOKEN_LIFETIME_SECONDS = 3600
KEY_ID = "mock-signing-key-1"

# ---------------------------------------------------------------------------
# Load seeded "app registrations" (see apps.json)
# ---------------------------------------------------------------------------
_seed = json.loads(Path(__file__).with_name("apps.json").read_text())
APPS = {a["client_id"]: a for a in _seed["apps"]}
APPS_BY_URI = {a["identifier_uri"]: a for a in _seed["apps"]}
USERS = {u["upn"]: u for u in _seed["users"]}

# ---------------------------------------------------------------------------
# Generate an RSA keypair at startup (like a real identity provider)
# ---------------------------------------------------------------------------
_private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
_private_pem = _private_key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption(),
).decode()
_public_numbers = _private_key.public_key().public_numbers()


def _b64url_uint(n: int) -> str:
    byte_len = (n.bit_length() + 7) // 8
    return base64.urlsafe_b64encode(n.to_bytes(byte_len, "big")).rstrip(b"=").decode()


JWKS = {
    "keys": [
        {
            "kty": "RSA",
            "use": "sig",
            "kid": KEY_ID,
            "alg": "RS256",
            "n": _b64url_uint(_public_numbers.n),
            "e": _b64url_uint(_public_numbers.e),
        }
    ]
}

# ---------------------------------------------------------------------------
# FastAPI app
# ---------------------------------------------------------------------------
app = FastAPI(title="Mock Entra ID")


@app.get("/health")
def health():
    return {"status": "ok", "tenant": TENANT, "issuer": ISSUER}


@app.get(f"/{TENANT}/v2.0/.well-known/openid-configuration")
def discovery():
    """OIDC discovery document - SDKs fetch this to learn endpoints & keys."""
    base = f"http://localhost:9100/{TENANT}"
    return {
        "issuer": ISSUER,
        "token_endpoint": f"{base}/oauth2/v2.0/token",
        "jwks_uri": f"{base}/discovery/v2.0/keys",
        "response_types_supported": ["token", "id_token", "code"],
        "subject_types_supported": ["pairwise"],
        "id_token_signing_alg_values_supported": ["RS256"],
        "grant_types_supported": [
            "client_credentials",
            "password",
            "urn:ietf:params:oauth:grant-type:jwt-bearer",
        ],
    }


@app.get(f"/{TENANT}/discovery/v2.0/keys")
def jwks():
    """Public keys used to verify JWT signatures."""
    return JWKS


# ---------------------------------------------------------------------------
# Token issuance helpers
# ---------------------------------------------------------------------------
def _sign(claims: dict) -> str:
    claims = {
        "iss": ISSUER,
        "iat": int(time.time()),
        "nbf": int(time.time()),
        "exp": int(time.time()) + TOKEN_LIFETIME_SECONDS,
        "jti": str(uuid.uuid4()),
        **claims,
    }
    return jwt.encode(claims, _private_pem, algorithm="RS256", headers={"kid": KEY_ID})


def _resolve_resource(resource_or_scope: str) -> dict:
    """Given 'api://api-b/.default' or 'api://api-b/Files.Read', return app."""
    value = resource_or_scope
    if value.endswith("/.default"):
        value = value[: -len("/.default")]
    # direct match first
    if value in APPS_BY_URI:
        return APPS_BY_URI[value]
    # otherwise strip trailing /<scope-name>
    trimmed = value.rsplit("/", 1)[0]
    if trimmed in APPS_BY_URI:
        return APPS_BY_URI[trimmed]
    raise HTTPException(400, f"unknown resource: {resource_or_scope}")


def _require_client(client_id: str, client_secret: str) -> dict:
    app_def = APPS.get(client_id)
    if not app_def or app_def["client_secret"] != client_secret:
        raise HTTPException(401, "invalid_client")
    return app_def


# ---------------------------------------------------------------------------
# Token endpoint - the one that matters
# ---------------------------------------------------------------------------
@app.post(f"/{TENANT}/oauth2/v2.0/token")
def token(
    grant_type: str = Form(...),
    client_id: str = Form(...),
    client_secret: str = Form(...),
    scope: str | None = Form(None),
    username: str | None = Form(None),
    password: str | None = Form(None),
    assertion: str | None = Form(None),
    requested_token_use: str | None = Form(None),
):
    caller = _require_client(client_id, client_secret)

    # --- client_credentials: app-to-app, no user --------------------------
    if grant_type == "client_credentials":
        if not scope or not scope.endswith("/.default"):
            raise HTTPException(400, "scope must be <resource>/.default")
        resource = _resolve_resource(scope)
        granted = caller.get("granted_app_roles", {}).get(resource["identifier_uri"], [])
        claims = {
            "aud": resource["identifier_uri"],
            "azp": client_id,                 # authorized party
            "sub": client_id,                 # subject == the app itself
            "oid": f"sp-{client_id}",         # service principal object id
            "roles": granted,                 # app roles granted on the resource
            "tid": TENANT,
        }
        return {
            "access_token": _sign(claims),
            "token_type": "Bearer",
            "expires_in": TOKEN_LIFETIME_SECONDS,
        }

    # --- password (ROPC): demo only, to obtain a user token ---------------
    if grant_type == "password":
        if not username or not password:
            raise HTTPException(400, "username/password required")
        user = USERS.get(username)
        if not user or user["password"] != password:
            raise HTTPException(401, "invalid_grant")
        scopes = [s for s in (scope or "").split() if s]
        resource = _resolve_resource(scopes[0]) if scopes else caller
        scp = " ".join(s.split("/")[-1] for s in scopes) or "access_as_user"
        claims = {
            "aud": resource["identifier_uri"],
            "azp": client_id,
            "sub": user["object_id"],
            "oid": user["object_id"],
            "upn": user["upn"],
            "name": user["name"],
            "scp": scp,                       # delegated scopes (space-separated)
            "tid": TENANT,
        }
        return {
            "access_token": _sign(claims),
            "token_type": "Bearer",
            "expires_in": TOKEN_LIFETIME_SECONDS,
        }

    # --- on-behalf-of: middle tier exchanges user token for downstream ----
    if grant_type == "urn:ietf:params:oauth:grant-type:jwt-bearer":
        if requested_token_use != "on_behalf_of" or not assertion:
            raise HTTPException(400, "requested_token_use=on_behalf_of and assertion required")
        # Validate the incoming user assertion (must be for the caller app)
        signing_key = jwk.construct(JWKS["keys"][0])
        try:
            inner = jwt.decode(
                assertion,
                signing_key.to_pem().decode(),
                algorithms=["RS256"],
                audience=caller["identifier_uri"],
                issuer=ISSUER,
            )
        except Exception as e:
            raise HTTPException(401, f"invalid assertion: {e}")

        if not scope:
            raise HTTPException(400, "scope required (downstream scope)")
        downstream = _resolve_resource(scope.split()[0])
        scp = " ".join(s.split("/")[-1] for s in scope.split())
        claims = {
            "aud": downstream["identifier_uri"],
            "azp": client_id,
            "sub": inner["sub"],
            "oid": inner["oid"],
            "upn": inner.get("upn"),
            "name": inner.get("name"),
            "scp": scp,
            "tid": TENANT,
        }
        return {
            "access_token": _sign(claims),
            "token_type": "Bearer",
            "expires_in": TOKEN_LIFETIME_SECONDS,
        }

    raise HTTPException(400, f"unsupported grant_type: {grant_type}")


@app.get("/debug/decode/{token_str}")
def debug_decode(token_str: str):
    """Developer convenience: see the claims in a token without verifying."""
    header = jwt.get_unverified_header(token_str)
    payload = jwt.get_unverified_claims(token_str)
    return JSONResponse({"header": header, "payload": payload})
