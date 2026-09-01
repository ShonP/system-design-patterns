# Azure Authentication — Identity & Service-to-Service

📖 **Reference**: [Microsoft Entra ID documentation](https://learn.microsoft.com/en-us/entra/identity-platform/)

## What you'll learn

When you build real systems on Azure, you constantly ask: *"How does service A call service B securely?"* The answer involves a confusing pile of terms: **app registration**, **service principal**, **managed identity**, **client credentials**, **on-behalf-of**, **DefaultAzureCredential**. This lab demystifies them with runnable code.

By the end you'll understand:

- What an **app registration** actually is (and how it differs from a service principal)
- How **service-to-service (S2S)** auth works with the **client credentials** flow
- The difference between **system-assigned** and **user-assigned managed identity**, and when to pick which
- What **On-Behalf-Of (OBO)** is, and why middle-tier APIs need it
- How **DefaultAzureCredential** lets the same code work locally *and* in Azure
- How JWTs, scopes, roles, and JWKS validation fit together

## The challenge: learning this without an Azure subscription

Real Entra ID (formerly Azure AD) requires a tenant. To make this lab fully runnable offline we ship a **tiny mock Entra server** that speaks the same OAuth2 / OIDC endpoints (`/oauth2/v2.0/token`, JWKS, discovery). The API code that consumes its tokens is **the same code** you would deploy to Azure — only the issuer URL changes.

For the real thing, see [`scripts/azure-setup.sh`](scripts/azure-setup.sh).

### What is real and what is simulated

Be precise about this before you copy anything into production:

| | Real | Simulated |
|-|------|-----------|
| Token signing | ✅ genuine RS256 JWTs, RSA keypair generated at startup | |
| Signature + `iss`/`aud`/`exp`/`nbf` validation in `common/auth.py` | ✅ this is production-shaped code | |
| JWKS publication and `kid`-based key selection | ✅ | key *rotation* never actually happens |
| `client_credentials` and On-Behalf-Of grants | ✅ same wire format as Entra | |
| Sign-in | | ROPC only. No authorization code, no PKCE, no browser, no consent screen |
| Managed identity | | **not simulated at all** — notebook 3 substitutes a client secret and says so |
| Conditional Access, MFA, claims challenges, CAE / revocation | | **none.** Every token the mock issues is valid for its full hour, no matter what |
| Consent, admin consent, app-role assignment | | pre-seeded in `fake-entra/apps.json` |
| `DefaultAzureCredential` / MSAL against the mock | | impossible — both SDKs refuse non-HTTPS authorities, so those cells are documentation-only |

Anywhere a notebook decodes a JWT with `base64.urlsafe_b64decode`, that is **inspection, not
validation** — it proves nothing about the token. The only real validator in this repo is
[`common/auth.py`](common/auth.py).

## Architecture

```
┌─────────────┐     1. get token       ┌──────────────────┐
│  Notebook   │───────────────────────▶│  Mock Entra ID   │
│  or CLI     │                         │  :9100           │
└─────────────┘                         │  /oauth2/token   │
       │                                │  /jwks           │
       │ 2. call API-A                  └──────────────────┘
       │    (user token)                        ▲  ▲
       ▼                                        │  │ 5. validate
┌─────────────┐     3. OBO exchange             │  │    JWT
│   API-A     │─────────────────────────────────┘  │
│   :8001     │                                    │
│  middle tier│     4. call API-B (downstream token)│
└─────────────┘────────────────────────────────────▶┌──────────────┐
                                                    │    API-B     │
                                                    │    :8002     │
                                                    │  resource    │
                                                    └──────────────┘
```

| Component      | Role                           | Real Azure equivalent              |
|----------------|--------------------------------|------------------------------------|
| Mock Entra     | Issues and validates JWTs      | Microsoft Entra ID tenant          |
| API-A          | Middle-tier web API            | App Service / Container App        |
| API-B          | Downstream resource API        | Any protected Azure-hosted API     |
| App configs    | `fake-entra/apps.json`         | App registrations in Entra portal  |

## Notebooks

| # | Notebook | Topic |
|---|----------|-------|
| 1 | [Concepts & tokens](notebooks/01_concepts_tokens_and_app_registrations.ipynb) | App registrations, service principals, JWT anatomy |
| 2 | [S2S client credentials](notebooks/02_service_to_service_client_credentials.ipynb) | Daemon app calls downstream API |
| 3 | [Managed identities](notebooks/03_managed_identities.ipynb) | System-assigned vs user-assigned, IMDS, why DefaultAzureCredential exists |
| 4 | [On-Behalf-Of flow](notebooks/04_on_behalf_of_flow.ipynb) | User → API-A → API-B with delegated identity |
| 5 | [Local development](notebooks/05_local_development_with_default_credential.ipynb) | `az login`, environment variables, credential chain |

## Prerequisites

- Docker + Docker Compose
- Python 3.10+
- Optional: [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) if you want to run against a real tenant

## Quick start

```bash
cd 08-enterprise/azure-authentication

# Start mock Entra, API-A, API-B
docker compose up -d --build

# Python env for the notebooks
uv sync
# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/
```

Then open any notebook and select the lab's `.venv` interpreter as the kernel (it shows as `Python 3 (.venv)` in the top-right of a VS Code notebook). If it doesn't show up, `Cmd+Shift+P` → **Reload Window**.

### Verify it's running

```bash
# Mock Entra discovery document
curl http://localhost:9100/contoso/v2.0/.well-known/openid-configuration | jq .

# API-B health
curl http://localhost:8002/health

# API-A health
curl http://localhost:8001/health
```

## Pre-seeded identities

These mirror what you'd create in the Entra portal. See [`fake-entra/apps.json`](fake-entra/apps.json).

| Type             | Name          | client_id                     | Purpose                                   |
|------------------|---------------|-------------------------------|-------------------------------------------|
| App registration | `api-a`       | `api-a-client-id`             | Middle-tier API. Has a client secret.     |
| App registration | `api-b`       | `api-b-client-id`             | Resource API. Exposes scopes & app roles. |
| App registration | `daemon-app`  | `daemon-client-id`            | Background job doing S2S calls.           |
| App registration | `reporting-daemon` | `reporting-daemon-client-id` | Daemon with **no** granted app roles (for 403 demo). |
| User             | `alice`       | user principal                | Human user for OBO demos.                 |

API-B exposes:

- **Delegated scope** `Files.Read` — requires a user to consent (used in OBO)
- **App role** `Files.Read.All` — granted to service principals (used in client credentials)

## Glossary (read this first)

- **Tenant** — your organization's Entra directory. Has a unique ID (GUID) and domain (e.g. `contoso.onmicrosoft.com`).
- **App registration** — the *definition* of an application: its client ID, redirect URIs, exposed scopes, app roles. Think of it as a *template*.
- **Service principal** — the *instance* of an app registration inside a tenant. When another tenant consents to your app, a service principal for it is created in *their* tenant. For single-tenant apps, registration and SP live side-by-side.
- **Client secret / certificate** — a password (or cert) the app uses to prove it is who it says it is, when asking for a token.
- **Managed identity** — Azure creates and rotates the credential for you. Your code never sees a secret. Two flavors:
  - *System-assigned*: tied to a single Azure resource (VM, Container App…). Deleted with it.
  - *User-assigned*: standalone resource you can attach to many.
- **OAuth2 scope (delegated permission)** — "this app may act on behalf of a signed-in user to do X".
- **App role (application permission)** — "this app itself may do X, no user involved".
- **Access token** — a signed JWT your app sends to downstream APIs in `Authorization: Bearer <token>`. Its `aud` is the *resource API*.
- **ID token** — a signed JWT that tells a *client app* who just signed in. Its `aud` is the client's own client ID, and it carries no `scp`/`roles`. **Never send an ID token to an API, and never accept one as a bearer credential** — a validator that checks `aud` rejects it automatically. See notebook 1.
- **Authorization code + PKCE** — the flow for getting a user token. PKCE (RFC 7636) is mandatory for public clients (SPA, mobile, CLI) which cannot hold a secret. The older **implicit flow** and **ROPC** (`grant_type=password`) are deprecated by RFC 9700 / OAuth 2.1 — this lab uses ROPC in notebook 4 *only* because a notebook cannot do a browser redirect.
- **Conditional Access** — tenant policies (require MFA, compliant device, trusted location) evaluated **per resource**. They can fail an On-Behalf-Of exchange at runtime with a *claims challenge* that only the user's browser can satisfy. See notebook 4.
- **DefaultAzureCredential** — an SDK helper that tries several credential sources in order (env vars → managed identity → Azure CLI → …) so the same code runs locally and in Azure.

## Running against real Azure (optional)

After you've explored locally, see [scripts/azure-setup.sh](scripts/azure-setup.sh) to create real app registrations and a user-assigned managed identity. The code in `api-a/` and `api-b/` only changes its issuer URL — everything else is identical.

## Cleanup

```bash
docker compose down -v
```
