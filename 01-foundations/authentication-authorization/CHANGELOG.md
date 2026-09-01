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

## 2026-08-20 (security-content audit)
- NB1: the SHA-256 crack demo now runs the **same wordlist against bcrypt** so the
  cost ratio is measured (~5,800x) rather than asserted in prose, with the rockyou.txt
  extrapolation spelled out. Added current OWASP parameters (Argon2id m=19MiB/t=2,
  scrypt N=2^17, bcrypt work factor >= 10, PBKDF2 >= 600k) and the target of a
  250-500 ms verify.
- NB1 **(new)**: the **bcrypt 72-byte limit** — bcrypt 5.x refuses long inputs, but
  older versions and other language bindings truncate silently, so two different
  passwords sharing a 72-byte prefix authenticate each other. This is the shape of the
  2024 Okta incident.
- NB2 **(new)**: `alg: none` and **algorithm confusion (RS256 -> HS256)** are now
  *executed*, not just named. Both attacks succeed against a permissive/hand-rolled
  verifier and are then rejected once the algorithm list is pinned. Added a six-point
  verification checklist (pin algorithms, verify signature, check `exp`/`nbf`, check
  `aud`/`iss`, remember it is not encrypted, keep them short-lived) and the note that a
  deny-listed JWT still passes signature verification on any service that doesn't
  consult the list.
- NB2: fixed a fragile `payload + "=="` base64 unpadding; asserted that tampering,
  expiry and revocation are all actually rejected.
- NB3: **PKCE is now implemented and attacked**, not mentioned in a footnote — a public
  client with no secret, S256 challenge/verifier, an intercepted code that fails
  without the verifier, and a public client that cannot opt out of PKCE.
- NB3: moved the access token out of the **query string** into an
  `Authorization: Bearer` header (RFC 6750) — the previous version taught a pattern
  that leaks tokens into access logs and `Referer` headers. Added runnable
  demonstrations of redirect-URI allow-listing (including three near-miss URIs),
  single-use authorization codes, wrong-client redemption, and `redirect_uri` binding
  at the token endpoint. Added an explicit warning that the demo's credential-passing
  is a notebook shortcut.
- NB3: promoted the authn-vs-authz distinction to the top of the notebook and expanded
  the OIDC section to explain why an access token is not a login.
- Dependency: added `cryptography` (for the RS256 keys in the algorithm-confusion demo).
- Hygiene: kernelspec set to `Python 3 (.venv)`, saved outputs stripped.
