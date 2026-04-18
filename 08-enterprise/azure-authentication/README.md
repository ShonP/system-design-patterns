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

## Architecture

```
┌─────────────┐     1. get token       ┌──────────────────┐
│  Notebook   │───────────────────────▶│  Mock Entra ID   │
│  or CLI     │                         │  :9000           │
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
cd enterprise-patterns/azure-authentication

# Start mock Entra, API-A, API-B
docker-compose up -d

# Python env for the notebooks
uv sync
uv run python -m ipykernel install --user --name=azure-auth --display-name="Azure Auth (Python)"
```

Then open any notebook and select the `Azure Auth (Python)` kernel (top-right of VS Code notebook). If it doesn't show up, `Cmd+Shift+P` → **Reload Window**.

### Verify it's running

```bash
# Mock Entra discovery document
curl http://localhost:9000/contoso/v2.0/.well-known/openid-configuration | jq .

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
- **Access token** — a signed JWT your app sends to downstream APIs in `Authorization: Bearer <token>`.
- **DefaultAzureCredential** — an SDK helper that tries several credential sources in order (env vars → managed identity → Azure CLI → …) so the same code runs locally and in Azure.

## Running against real Azure (optional)

After you've explored locally, see [scripts/azure-setup.sh](scripts/azure-setup.sh) to create real app registrations and a user-assigned managed identity. The code in `api-a/` and `api-b/` only changes its issuer URL — everything else is identical.

## Cleanup

```bash
docker-compose down -v
```
