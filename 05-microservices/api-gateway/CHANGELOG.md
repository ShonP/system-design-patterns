# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19 — QA Review
- Fixed stale path references (`deep-dives/` → `05-microservices/`) in all 3 notebooks.
- Rewrote `nginx.conf` with structured access logs (`/dev/stdout`, `$upstream_response_time`), CORS preflight handling (`always` headers), circuit-breaker-style failover (`max_fails`/`fail_timeout`/`proxy_next_upstream` — noted as passive failover, not full circuit breaker), request aggregation route, and commented SSL termination block (concept-only).
- Added aggregation endpoint (`/users/<id>/profile`) to `user_service.py` using stdlib `urllib.request` with timeout + partial-failure handling.
- Added NB4: Advanced Patterns — covers resilience/failover, request aggregation/BFF, CORS, observability/logging, and SSL termination concepts. All code cells syntax-checked.
- Updated README with NB4, expanded Core Responsibilities list (resilience, aggregation, CORS, observability, SSL termination).
- +955/-1 lines across 6 files.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
