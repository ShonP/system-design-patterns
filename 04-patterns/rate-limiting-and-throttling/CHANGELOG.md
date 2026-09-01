# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20

### Fixed
- `03_sliding_window.ipynb` — the boundary-burst "demo" faked the window roll by reaching
  into the limiter (`fw.start -= 1.0`). It now runs against the real clock: the limiter
  resets on clock-aligned windows, and the attack waits for a boundary, spends its budget,
  crosses, and spends it again — 10 requests in ~0.10 s through a 5 req/s limiter.
- `03_sliding_window.ipynb` — the comparison plot drove a 6 req/s stream through a 5 req/s
  limiter, so the "2× the limit" it claimed to show was arithmetically impossible (peak
  could not exceed 6). Replaced with a deterministic replay of a recorded boundary-attack
  trace; the fixed window now visibly peaks at 10 while the sliding log holds at 5.
- `02_leaky_bucket.ipynb` — the notebook described the leaky bucket as pacing output but
  implemented an admission limiter, and the "token vs leaky" plot drew both at *arrival*
  time, so the two lines were identical and demonstrated nothing.
- `02_leaky_bucket.ipynb` — GCRA allowed `burst + 1` requests from idle (tolerance was
  `burst` intervals rather than `burst - 1`).

### Added
- `03_sliding_window.ipynb` — measurement of the sliding-window **counter's approximation
  error**: front-loaded traffic makes it reject 19 of 40 in-limit requests, back-loaded
  traffic makes it exceed the limit by 5%. Plus explicit "when to use which" guidance.
- `02_leaky_bucket.ipynb` — the shaper/limiter distinction stated up front, a real
  `ShapingLeakyBucket` that returns each request's **service time**, a plot of arrivals vs
  limiter output vs shaper output, the worst-case added latency, and a "when NOT to shape"
  section. GCRA now also returns `Retry-After`.
- `04_distributed_and_backoff.ipynb` — the **read-then-write race**: 60 concurrent
  requests through a naive `get`/`set` shared counter all pass a limit of 10 and 59
  increments are lost. Fixed with a single-round-trip atomic check-and-increment. The
  limiter now returns real `429` responses with a computed `Retry-After` that counts down,
  plus what the shared store costs (extra hop, hard dependency, hot keys, clock skew).
- `01_token_bucket.ipynb` — `HttpTokenBucket` computing an exact `Retry-After` from the
  token deficit, and an expanded when-to-use / when-not-to-use with the cost of each knob.

### Changed
- Hygiene: kernelspec normalized to `Python 3 (.venv)`; saved outputs and execution counts
  stripped from all six notebooks. Limiters take an optional injected `now`, so plots
  replay recorded traces deterministically instead of racing the wall clock.

## 2026-04-19 (later)
- QA re-review: re-executed all notebooks end-to-end — all pass.
- **Fixed** a correctness bug in `04_distributed_and_backoff.ipynb`: the simulated shared store recorded rejected requests, inflating the window and starving future traffic. Replaced with an atomic `check_and_add` and added a Redis-ready Lua script (with unique-member note).
- **Added** GCRA (Generic Cell Rate Algorithm) section to `02_leaky_bucket.ipynb` — the one-timestamp leaky bucket used by Redis `redis-cell`, Shopify, CDNs. Clear caveat that it's admission-control, not output-smoothing.
- **Added** observability section to `05_concurrency_and_practice.ipynb` — which metrics to emit (allowed/denied counters, retry-after histogram, store-error counter, heavy-hitter sampling) and why labeling metrics with high-cardinality keys is a trap.
- **Added** a real-world limits table to `00_intro.ipynb` (GitHub, Stripe, Discord, AWS, Cloudflare…) so beginners see concrete numbers and which algorithm each vendor uses.

## 2026-04-19
- QA review: verified all notebooks execute cleanly end-to-end; added `05_concurrency_and_practice.ipynb` covering concurrency limits (semaphore), cost-based limits, where to enforce (edge / gateway / service), fail-open vs fail-closed, and how to choose the limit key (IPv4 NAT, IPv6 `/64`, `X-Forwarded-For` traps).
- QA pass: added `00_intro.ipynb` (why rate limit, 429 / Retry-After headers) and `04_distributed_and_backoff.ipynb` (Redis-style shared counter, client-side exponential backoff with full jitter).
- Rewrote `01`, `02`, `03` to follow bad → best progression and added matplotlib visualizations (allowed/denied timelines, token-vs-leaky pacing, fixed-vs-sliding boundary burst).
- Added per-key token bucket example and O(1) sliding-window-counter (Cloudflare-style hybrid).
- Updated `README.md` to list all five notebooks and the concepts they cover.

## 2026-04-18
- Scaffolded `Rate Limiting And Throttling` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
