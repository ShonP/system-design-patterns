# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20

### Fixed
- `04_timeouts_and_graceful_degradation.ipynb` — the "BAD: no timeout" case was prose plus
  `print('skipping — this would block 30s')`. It now actually runs: four stuck calls take
  every thread in a 4-worker pool and a healthy request is still queued a second later.

### Added
- `04_timeouts_and_graceful_degradation.ipynb` — a demo that **a missing timeout defeats
  every other mechanism**: the same breaker + retry wrapper around a dependency that
  answers 1 s late stays `CLOSED` forever without a timeout (it never sees a failure to
  count) and trips correctly with one.
- `04_timeouts_and_graceful_degradation.ipynb` — **load shedding** (Part 4): goodput
  collapse measured over two rounds, showing that an unshed server's own client timeouts
  become its next wave of load; plus shed-by-priority guidance and when not to shed.
- `04_timeouts_and_graceful_degradation.ipynb` — **health checks** (Part 5): liveness vs
  readiness vs startup, and a runnable demo of the classic backwards implementation where
  a deep readiness check turns a non-critical dependency blip into a 100% fleet outage.
- `03_bulkhead.ipynb` — what partitioning costs (lower utilization, more knobs, and the
  fact that `ThreadPoolExecutor`'s unbounded queue is not a bulkhead), and when not to use
  one.

### Changed
- The stacking diagram and pattern table now include load shedding and health checks, and
  every pattern has an explicit "when NOT to use it" column.
- Hygiene: kernelspec normalized to `Python 3 (.venv)`; saved outputs and execution counts
  stripped from all five notebooks.

## 2026-04-18
- Scaffolded `Resilience` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-19
- Rewrote `01_retry_with_backoff.ipynb`: added matplotlib visualization of the thundering-herd vs jittered retry distribution, plus real-world notes (idempotency, retry budgets, `tenacity`).
- Rewrote `02_circuit_breaker.ipynb`: added a BAD "no breaker — keep hammering" baseline for contrast, clearer step-by-step comments in the breaker, and real-world refinements (rate-based tripping, exponential cooldown, per-downstream breakers).
- Rewrote `03_bulkhead.ipynb`: added an `asyncio.Semaphore` bulkhead example for async Python.
- **New** `04_timeouts_and_graceful_degradation.ipynb`: hard timeouts (with a threading-based demo), fallback to default / stale cache, feature-flag kill switches, and a layered diagram showing how all the patterns stack.
- Updated `README.md` notebook listing.

## 2026-04-19 (QA pass)
- **New** `05_stacking_all_patterns.ipynb`: capstone that composes timeout + retry-with-jitter + thread-safe `CircuitBreaker` (with `Lock`) + bounded-semaphore `Bulkhead` (fast-fail admission control) + two-tier fallback into one `product_page(user)` pipeline. Includes a naive-baseline run, a broken-downstream run, and a recovered run, with per-run metrics (downstream calls, breaker fast-fails, bulkhead rejections, result mix). All cells execute in under ~3 s.
- Verified notebooks 01–04 still run end-to-end under `jupyter nbconvert --execute`.
- Updated `README.md` notebook listing.

## 2026-04-19 (review pass)
- `01_retry_with_backoff.ipynb`: fixed seed so the exponential / jitter cells actually demonstrate retries (seed 0 → first call succeeded, printed empty `delays: []`). Added a new **idempotency keys** section with a runnable "retry without key → alice is billed 5× for one purchase" vs "stable caller-generated key → server dedupes to 1 charge" demo, plus a `ValueError` guard showing the same-key-different-params bug.
- `02_circuit_breaker.ipynb`: added a matplotlib per-call latency visualization contrasting **no breaker** (flat ~200 ms/call) against **with breaker** (first few at 200 ms, then ~0 ms fast-fail). Uses a long cooldown so the chart is deterministic. Final run prints total wall-time savings (~10× faster).
- `README.md`: removed stale "scaffolded — notebooks will be added incrementally" line; all 5 notebooks are in place.
