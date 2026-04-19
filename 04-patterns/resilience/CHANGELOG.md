# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Resilience` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-19
- Rewrote `01_retry_with_backoff.ipynb`: added matplotlib visualization of the thundering-herd vs jittered retry distribution, plus real-world notes (idempotency, retry budgets, `tenacity`).
- Rewrote `02_circuit_breaker.ipynb`: added a BAD "no breaker — keep hammering" baseline for contrast, clearer step-by-step comments in the breaker, and real-world refinements (rate-based tripping, exponential cooldown, per-downstream breakers).
- Rewrote `03_bulkhead.ipynb`: added an `asyncio.Semaphore` bulkhead example for async Python.
- **New** `04_timeouts_and_graceful_degradation.ipynb`: hard timeouts (with a threading-based demo), fallback to default / stale cache, feature-flag kill switches, and a layered diagram showing how all the patterns stack.
- Updated `README.md` notebook listing.
