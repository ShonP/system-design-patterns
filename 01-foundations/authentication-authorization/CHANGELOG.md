# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Authentication & Authorization` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
- Added three notebooks: `01_password_hashing.ipynb`, `02_sessions_vs_jwt.ipynb`, `03_oauth_flow_demo.ipynb`.
- QA pass: extended notebooks with missing essentials.
  - NB1: live SHA-256 dictionary-crack demo, salt demo bridging to bcrypt, pepper note, Argon2/scrypt + constant-time compare, real-world breach context.
  - NB2: fresh-token tamper demo (fixes expired-token ambiguity), `jti` deny-list revocation store, cookie flag notes, `alg:none` warning, HS256 vs RS256 note.
  - NB3: `state` (CSRF), redirect-URI allow-list, scopes, short-lived access token with `refresh_token` exchange, PKCE and OIDC recap.
