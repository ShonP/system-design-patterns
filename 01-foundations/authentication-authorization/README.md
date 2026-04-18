# Authentication & Authorization

> Part of `01-foundations/`. Uses FastAPI for the OAuth demo — runs in-process via the test client, so **no Docker required**.

## Learning objectives

- Tell authentication from authorization and name canonical mechanisms for each.
- Compare server-stored sessions vs JWTs (trade-offs on revocation, size, statelessness).
- Explain OAuth 2.0 roles and flows at a conceptual level, plus where JWT fits in.
- Understand why password storage requires *slow*, *salted* hashing (bcrypt).

## Concepts covered

- AuthN vs AuthZ
- Password hashing: plain → SHA-256 → salted SHA-256 → bcrypt with cost factor
  - live dictionary-crack demo, pepper, constant-time compare, Argon2/scrypt
- Sessions vs JWTs; revocation via deny-list; expiry; tamper-proofing
  - cookie flags (HttpOnly/Secure/SameSite), `alg:none` footgun, HS256 vs RS256
- OAuth 2.0 Authorization Code flow with two tiny FastAPI apps
  - `state` (CSRF), redirect-URI allow-list, scopes, access/refresh tokens
  - PKCE and OpenID Connect (id_token) explained

## Setup

This lab is managed with [`uv`](https://docs.astral.sh/uv/) and uses its own `.venv`.

```bash
cd 01-foundations/authentication-authorization
uv sync
```

Then open any notebook in VS Code and select the `.venv` kernel from the kernel picker (top-right of the notebook). If the kernel doesn't show up, reload the window: `Cmd+Shift+P` → **Reload Window**.

There are no external services — everything runs in-process in Python.

## Notebooks

- [`notebooks/01_password_hashing.ipynb`](./notebooks/01_password_hashing.ipynb) — bad/better/best for storing passwords: plain text → SHA-256 → bcrypt with salt and cost factor.
- [`notebooks/02_sessions_vs_jwt.ipynb`](./notebooks/02_sessions_vs_jwt.ipynb) — server-side sessions vs JWTs. See revocation, expiry, and tampering in action.
- [`notebooks/03_oauth_flow_demo.ipynb`](./notebooks/03_oauth_flow_demo.ipynb) — full OAuth 2.0 Authorization Code flow simulated with two FastAPI apps.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
