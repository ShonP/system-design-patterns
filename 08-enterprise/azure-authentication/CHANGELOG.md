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
