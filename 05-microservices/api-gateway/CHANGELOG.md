# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19 — QA Review (round 4)
- Fixed NB2 accuracy bug: the "How a Sliding Window Rate Limiter Works" section actually describes and implements a **fixed-window** counter (bucketed by `floor(now / window_seconds)`). Renamed the section to "How a Fixed-Window Rate Limiter Works", clarified the algorithm steps, and added a callout explaining the *burst-at-the-boundary* weakness that motivates true sliding-window counters (which are covered in the summary table).
- Fixed the NB2 "Interview Tip" which claimed we implemented a sliding-window counter; now mentions both algorithms honestly.
- Added a new **Real-World API Gateway Products** section to NB4 comparing nginx, Envoy, Kong, Traefik, HAProxy, AWS API Gateway, Azure APIM, Apigee, Cloudflare/Fastly, and Istio/Linkerd — with a quick heuristic for picking one. This closes the "nginx-only" gap so learners know the patterns they just learned map 1:1 to every major gateway product.
- Re-executed NB2 and NB4 end-to-end against the live stack — all cells pass and saved outputs reflect real runs.

## 2026-04-19 — QA Review (round 3)
- Fixed NB1 load-balancing demo: learners were hitting the gateway's 5 req/sec rate limiter when running the round-robin loop, which returned a plain-text 429 and crashed `r.json()`. Added a 0.25s throttle between requests plus a retry on 429 so the cell now reliably shows a clean 50/50 distribution across the two user-service instances.
- Fixed NB1 latency comparison: same rate-limit issue. Added throttle parameter and lowered sample size from 20 → 10.
- Fixed NB4 aggregation benchmark: the client-side vs. gateway-side composition benchmark was firing 2 requests per iteration × 10 iterations with no pause, tripping the gateway rate limiter. Added throttle, subtracted throttle time from reported latency, and lowered N from 10 → 5.
- Re-executed all four notebooks end-to-end against the running stack (`docker-compose up -d --build` + `uv run jupyter nbconvert --execute`). All cells now complete without errors and the saved outputs reflect real runs (LB 50/50, canary ~90/10, aggregation response, etc.).

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
