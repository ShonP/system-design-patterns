# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Moved mock Entra from port 9000 → 9100 to avoid conflicts with minio and other common dev containers.
- Added `reporting-daemon` pre-seeded app (no granted roles) so notebook 2 can demo a real "403 missing app role" scenario instead of only a wrong-secret case.
- Added a "Bad → best: why bother with all this?" progression to notebook 1 (shared API key → self-signed HS256 JWT → Entra RS256 + JWKS), with a signature-tampering demo that proves the JWT is actually verified.
- Made notebooks 2, 3 and 5 runnable end-to-end against the mock: replaced MSAL / `EnvironmentCredential` / `DefaultAzureCredential` *instantiations* with documentation-only snippets (those SDKs reject non-HTTPS authorities). Raw HTTP + `httpx` demos continue to work.
- Verified every notebook executes cleanly via `jupyter nbconvert --execute`.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.

## 2026-08-21 (correctness audit)
- **Token validation hardened (`common/auth.py`).** `python-jose` *silently skips* `aud` and
  `exp` when the claim is absent (`_validate_aud` / `_validate_exp` both open with
  `if "aud"/"exp" not in claims: return`), so a validly signed token carrying neither passed
  `jwt.decode(..., audience=..., issuer=...)` as "valid for any audience, forever". Now passes
  `options={"require_aud", "require_exp", "require_iat", "require_nbf", "require_iss",
  "require_sub"}` plus 60s of clock skew, and documents the trap in the module docstring.
- **JWKS re-fetch on unknown `kid`.** Notebook 1 claimed "automatic key rotation via `kid` →
  JWKS; validators re-fetch" but the validator only refreshed on a 300s TTL, so a key roll
  produced up to five minutes of 401s. `_get_jwks(force=True)` now re-fetches once on an
  unknown `kid`, rate-limited to one forced fetch per 10s so a bogus-`kid` flood cannot
  amplify requests at the IdP.
- **"Decoding is not validating" is now stated in the loudest possible terms.** Every
  `decode_jwt` / `decode_payload` helper (notebooks 1, 2, 4) is labelled inspection-only, and
  the mock's `/debug/decode` endpoint carries the same warning. Notebook 1's tamper demo was
  upgraded to a real forgery — it rewrites the payload to `roles: ["Global.Admin"]`, shows
  that it decodes perfectly, and asserts api-b answers 401.
- **New: ID token vs access token** (notebook 1 + README glossary), including why an API must
  never accept an ID token as a bearer credential and why a correct `aud` check rejects one
  for free.
- **New: which OAuth2 flow for which caller** (notebook 1) — authorization code + PKCE as the
  answer for public clients, and explicit deprecation notices for the **implicit flow**
  (RFC 9700 / OAuth 2.1) and **ROPC**. Notebook 4's ROPC caveat was rewritten from "not
  supported for multi-factor accounts" to the full picture.
- **New: Conditional Access, MFA claims and CAE** (notebook 4) — `interaction_required` on the
  OBO exchange, the `WWW-Authenticate: ... error="insufficient_claims"` relay, and the `amr` /
  `acrs` / `auth_time` / `xms_cc` claims. Also flags the confused-deputy trap in
  `/proxy/files/admin` and states plainly that the mock has no revocation at all.
- **New: certificate vs client secret** (notebook 2), with the credential preference order
  managed identity → workload identity federation → certificate → secret, plus token-caching
  guidance and the note that client credentials has no refresh token.
- **Honesty pass on notebook 3.** The prose said "let's prove it works with real
  `DefaultAzureCredential` code pointed at our mock Entra" while the cell below did a raw
  `client_credentials` POST with a hard-coded secret. Replaced with an explicit real-vs-
  simulated table: managed identity is *not* simulated, only the resulting token shape
  matches. A matching table was added to the README.
- **Notebook 5**: "enable debug logging (see cell above)" referred to a cell that did not
  exist — added the actual `azure.identity` DEBUG logging snippet (and the warning that
  `logging_enable=True` writes bearer tokens to your logs). Marked `SharedTokenCacheCredential`
  and `VisualStudioCodeCredential` deprecated, and added guidance to pin the credential in
  deployed services rather than ship a bare `DefaultAzureCredential()`.
- **Assertions added throughout** so the lab fails loudly if it stops reproducing its own
  lesson: app-only tokens carry `roles` and no `upn`/`scp`; an ungranted role is **403** while
  a wrong `aud` or bad signature is **401**; a bad secret yields no token at all; OBO preserves
  `oid`/`upn` while re-targeting `aud` and `scp`; a raw user token forwarded to api-b is
  rejected; OBO without the middle tier's secret is rejected; the delegated call returns
  exactly Alice's two files while the app-only call returns all three (and strictly more).
- **Fixes**: README architecture diagram said mock Entra `:9000` (it moved to `:9100` in
  2026-04-20); README and notebook 1 told readers to select a kernel named
  `Azure Auth (Python)` that does not exist (the kernelspec is `Python 3 (.venv)`).
- The mock's OBO assertion check now also requires `aud`/`exp`/`sub` to be present.
- Verified: all five notebooks execute cleanly with every new assertion passing, against
  fake-entra / api-a / api-b run locally; `tools/validate_labs.py` reports 0 errors,
  0 warnings.
- Bumped `python-jose[cryptography]` from a hard `==3.3.0` pin to `>=3.5.0` (lock updated to
  3.5.0). 3.3.0 carries CVE-2024-33663 (algorithm confusion) and CVE-2024-33664 (JWE
  decompression DoS). Neither was reachable here — the validator pins `algorithms=["RS256"]`
  and the lab never touches JWE — but a lab that teaches token validation should not ship a
  vulnerable JWT library. All five notebooks re-executed on 3.5.0 and pass.
