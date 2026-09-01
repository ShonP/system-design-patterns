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
- Re-executed all four notebooks end-to-end against the running stack (`docker compose up -d --build` + `uv run jupyter nbconvert --execute`). All cells now complete without errors and the saved outputs reflect real runs (LB 50/50, canary ~90/10, aggregation response, etc.).

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

## 2026-08-21 (correctness audit)

Read-only audit of all four notebooks plus `nginx.conf`, `user_service.py` and the
README, looking for places where the prose, the code and the printed output
disagree. Several did.

### Security / trust boundary
- **`nginx.conf` let clients forge `X-Authenticated`.** `/api/auth/*` sets
  `X-Authenticated: true` after checking the API key, but every *other* route
  (`/api/users`, `/api/orders`, `/api/v2/users`, `/api/debug/headers`,
  `/api/cors/users`, `/api/canary/users`, `/api/profile/N`) said nothing about
  that header — and nginx forwards unknown client headers verbatim. A client
  could send `X-Authenticated: true` to an open route and the backend could not
  tell it apart from a real authenticated request. Every non-auth `location` now
  carries `proxy_set_header X-Authenticated "";`, with a comment block at the top
  of the file explaining the overwrite/clear/forward rule.
- **NB3: new "The gateway is a trust boundary" section.** Forges
  `X-Authenticated`, `X-Real-IP`, `X-Request-ID` and `X-Forwarded-For` from the
  client and asserts what survives. Also explains that
  `$proxy_add_x_forwarded_for` *appends*, so the attacker's entry is still in the
  chain — read XFF from the right, and trust only as many entries as you have
  proxies you control.
- README gained a **"What This Lab Does NOT Do"** section: auth here is static API
  keys in an nginx `map`, not JWT — no signature verification, no expiry, no
  revocation without a reload.

### Rate limiting (the arithmetic)
- **NB2: the burst-at-the-boundary bug was described but never reproduced.** Added
  a section that lines up on a fixed-window rollover, fires `limit` requests on
  each side, and asserts that **2x the limit** gets through inside a span shorter
  than one window. Then fixes it with a sliding-window log implemented as an
  **atomic Lua script** (a check-then-write in Python around three Redis calls is
  a race, not a limiter) and asserts the same attack is capped at `limit`.
- **NB2 cell 9 never explained where its numbers come from.** `limit_req` is a
  leaky bucket: instantaneous capacity is `1 + burst = 11`, then refill at
  `rate`. The cell now drains the bucket first, predicts `11 .. 11 + 5*T`, prints
  the prediction next to the actual, and asserts it.
- Algorithm summary table rewritten with a "boundary burst?" column and memory
  cost per algorithm; the interview tip now says *why* to pick sliding window.

### Resilience (NB4)
- **Circuit breaker demo was wall-clock dependent.** Whether request 6 crossed the
  2s recovery window depended on accumulated request overhead. The breaker now
  takes an injected `clock`, the demo drives it with a `VirtualClock`, and it
  asserts the exact transition sequence
  `open → half_open → open → half_open → open → half_open → closed`, plus that 6
  of 15 requests were short-circuited (load shed off a backend that is already
  down). Also runs instantly instead of sleeping 9.6s. Added a distinct
  `CircuitOpen` exception — the whole value of a breaker is that this failure is
  free, and a caller must be able to tell it from a real backend error.
- **New section: retry amplification.** Nested retries multiply
  (`3 x 2 x 3 = 18`), not add, and the multiplier peaks exactly when the backend
  is sickest. Seeded Monte-Carlo table of backend-calls-per-user-request vs.
  failure probability, asserting the worst case equals the product and that
  amplification grows monotonically with `p`. Kept honest: the success columns
  show retries *buy* availability (98% vs 36% at p=0.8) — the price is the
  multiplier.
- **New section: timeout budgets.** Parses the real numbers out of `nginx.conf`
  and `user_service.py` and asserts the budget strictly shrinks with depth
  (10s client → 5s gateway → 1.5s service). Writing it exposed a genuine
  subtlety: `proxy_next_upstream_tries 2` alone would allow 2 x 5s = 10s and blow
  the client deadline — it is `proxy_next_upstream_timeout 5s` that actually
  bounds it. A retry count without a total cap is not a budget.
- **Aggregation partial-failure was claimed, never shown.** New cell runs the same
  composition logic against a local stub that answers too slowly and against a
  dead port, asserting the call stays inside the timeout budget, the user half
  still returns, and the partial-failure flag is set.
- **`user_service.py`: `order_count` reported `0` when the orders call failed.**
  That is an unverified claim ("this user has no orders") presented as a fact, and
  a UI would render it as an empty order history during an outage. Now `null`
  when `orders_unavailable`.

### Prose vs. printed output
- **NB1 claimed the gateway adds "<1ms"** in both the comparison cell and the
  summary; its own output printed ~1.4ms, and the measurement is really
  dominated by Docker Desktop port forwarding. Rewritten to say what is actually
  being measured, with an assertion that the gateway costs one hop rather than
  multiplying latency.
- **NB1 and NB3 said nginx "automatically removes unhealthy backends".** nginx OSS
  has no active health checks — `depends_on: service_healthy` only gates startup,
  and `max_fails`/`fail_timeout` ejects a backend *after* real requests to it have
  already failed. This also contradicted NB4's own comparison table. Corrected in
  NB1 (routing section, health-check cell, summary table) and NB3 (capability
  table).
- **NB4 claimed "it won't be exactly 90/10 — weighted round-robin is
  approximate".** The saved output was exactly 90/10, because nginx uses *smooth*
  weighted round-robin: a deterministic rotation with period `sum(weights)`. The
  cell now explains what actually causes drift in production (per-worker rotation
  state without a shared `zone`; failed peers consuming slots) and warns that
  deterministic ≠ sticky.
- **NB4 aggregation benchmark said "on localhost the gap is small"** while
  printing a ~2x gap. Rewritten to explain what the number is (two far hops vs.
  one) and to add two honest caveats: a real client can parallelise its two
  calls, and aggregation *moves* the fan-out into the BFF rather than removing it.

### Garbled markdown (words interleaved mid-sentence)
- **NB2 cell 5** — the three Redis bullets were spliced into each other
  (`"Redis is **fast** (in- adds almost no latencymemory)"`), the fixed-window
  ASCII diagram was scrambled, and step 5 of the algorithm ("reject the request")
  had lost its number and its sentence. Section rewritten.
- **NB4 "Real-World API Gateway Products"** — the `##` heading was empty, the
  intro sentence had `menu` spliced into the middle of it, and all five "Quick
  heuristic" bullets had lost their leading product name, leaving five sentence
  fragments. Restored.

### Determinism and robustness
- `worker_processes 1;` added to `nginx.conf` with an explanatory comment. nginx
  keeps round-robin state per worker unless the upstream declares a shared-memory
  `zone`, so with the default `worker_processes auto` the load-balancing splits
  drift for reasons unrelated to the lesson. This is what makes NB1's exact 5/5
  and NB4's exact 90/10 assertions safe.
- **NB2 cell 4 had a data race**: 10 threads doing `results["success"] += 1` on a
  shared dict (load-add-store, updates can be lost). Now collects return values.
- **NB4 canary loop skipped its own throttle on error** (`continue` before
  `time.sleep`), so a 429 made the loop hammer the gateway *faster* — a feedback
  loop precisely when it was already being rate-limited. Now retries with backoff
  and always throttles.
- NB1 cell 10 retried a 429 exactly once and then called `.json()` regardless;
  now retries a few times and asserts a 200.
- NB2 cell 6 now clears its own Redis keys first, so re-running the cell doesn't
  continue a half-full counter.
- NB1's client-side load-balancing demo seeds its RNG.
- README: the aggregation endpoint was documented as `GET /api/users/:id/profile`;
  the actual route is `GET /api/profile/:id` (`/api/users/...` would hit the users
  location and 404 on the backend).

### Assertions added
Every one of these fails loudly if the lab stops demonstrating its own lesson:
NB1 — round-robin splits exactly in half; gateway overhead is one hop.
NB2 — unprotected service accepts all 50 requests; fixed window admits exactly
5 then blocks 3; **fixed window leaks exactly 2x at the boundary**; sliding
window caps the same attack at the limit; `limit_req` admits `1 + burst` plus
refill and does fire.
NB3 — request IDs are unique and injected; forged `X-Authenticated` is cleared,
forged `X-Real-IP` and `X-Request-ID` are overwritten, real peer is last in XFF;
the direct-call backend does echo the client's forged ID.
NB4 — exact circuit-breaker transition sequence and 6/15 requests shed; retry
amplification equals the product of per-layer tries and grows with `p`;
aggregation degrades inside its timeout budget with `order_count is None`;
timeout budget strictly shrinks and retries are bounded by a total cap; canary
split is exactly 90/10 and genuinely weighted; one round-trip beats two.
