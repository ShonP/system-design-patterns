# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19 — QA Review (round 2)
- Added **canary / weighted routing** as a new advanced pattern in NB4 (section 3️⃣, between request aggregation and CORS). Uses nginx weighted upstream servers — no service mesh required. Renumbered CORS/Observability/SSL sections to 4/5/6 accordingly.
- Added `upstream user_canary_backend` (weight 9:1) and `/api/canary/users` location in `nginx.conf`. Pretends `user-service-1` is stable and `user-service-2` is canary.
- Added a "close cousins" table (Blue/Green, Canary, Shadow, A/B) plus production canary tips (start tiny, watch p95/business KPIs, automate with Argo Rollouts/Flagger, stickiness, feature flags).
- Fixed NB4 circuit-breaker demo: bumped the simulation loop from 12 to 16 iterations so learners actually see the `OPEN → HALF_OPEN probe → CLOSED` recovery path (verified with a standalone Python run).
- README + NB4 summary/intro tables updated to include canary routing.

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
