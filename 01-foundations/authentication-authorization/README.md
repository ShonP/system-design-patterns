# Authentication & Authorization

> Part of `01-foundations/`. Uses FastAPI for the OAuth demo — runs in-process via the test client, so **no Docker required**.

## Learning objectives

- Tell authentication from authorization and name canonical mechanisms for each.
- Compare server-stored sessions vs JWTs (trade-offs on revocation, size, statelessness).
- Explain OAuth 2.0 roles and flows at a conceptual level, plus where JWT fits in.
- Understand why password storage requires *slow*, *salted* hashing (bcrypt), and measure the attacker-cost difference.
- Break JWT verification (`alg: none`, RS256->HS256 confusion) and then fix it.
- Run a full OAuth 2.0 + **PKCE** flow and watch each protection reject a real attack.

## Concepts covered

- AuthN vs AuthZ
- AuthN vs AuthZ (and why an OAuth access token is not a login)
- Password hashing: plain → SHA-256 → salted SHA-256 → bcrypt with cost factor
  - live dictionary crack run against *both* SHA-256 and bcrypt, pepper, constant-time
    compare, current OWASP parameters for Argon2id/scrypt/bcrypt/PBKDF2
  - the **bcrypt 72-byte limit** and how it silently disables passwords
- Sessions vs JWTs; revocation via deny-list; expiry; tamper-proofing
  - working **`alg: none`** and **RS256→HS256 algorithm-confusion** attacks, then the fix
  - a six-point verification checklist; cookie flags (HttpOnly/Secure/SameSite);
    HS256 vs RS256
- OAuth 2.0 Authorization Code flow with two tiny FastAPI apps
  - `state` (CSRF), exact-match redirect-URI allow-list, single-use codes, scopes,
    `Authorization: Bearer` (never a query string), access/refresh tokens
  - **PKCE implemented and attacked** for a public client; OpenID Connect (`id_token`)

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
- [`notebooks/02_sessions_vs_jwt.ipynb`](./notebooks/02_sessions_vs_jwt.ipynb) — server-side sessions vs JWTs. See revocation, expiry, tampering, `alg: none`, and algorithm confusion in action.
- [`notebooks/03_oauth_flow_demo.ipynb`](./notebooks/03_oauth_flow_demo.ipynb) — full OAuth 2.0 Authorization Code + PKCE flow simulated with two FastAPI apps, with every protection demonstrated by an attack that fails.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
