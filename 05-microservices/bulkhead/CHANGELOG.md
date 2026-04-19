# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Bulkhead` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_introduction.ipynb, 02_worked_example.ipynb.

## 2026-04-19
- QA pass: rewrote both notebooks with clearer bad→best progression.
  - `01_introduction.ipynb`: added motivating example of resource starvation,
    semaphore-based bulkhead variant, and a table of other resources to bulkhead.
  - `02_worked_example.ipynb`: restructured around an Order Service calling
    Inventory + Shipping. Added a mixed-traffic demo that shows a shipping-only
    endpoint staying at ~50 ms even while inventory is overloaded (vs ~2 s
    without bulkheads). Added pool-sizing formula, real-world tools table
    (Resilience4j, Polly, Envoy, Hystrix, k8s), exercises, and "when not to
    use" guidance.
  - Verified both notebooks execute end-to-end with `jupyter nbconvert --execute`.

## 2026-04-19 (QA round 2)
- `01_introduction.ipynb`: added a **modern asyncio bulkheads** section with a
  runnable `asyncio.Semaphore` example (payments vs. catalog) — matches what
  most FastAPI/aiohttp services actually need.
- `02_worked_example.ipynb`:
  - Removed executor leak in the "bad" and "good" demos (one shared caller
    pool + proper `shutdown(wait=True)` instead of four throwaway executors).
  - Added a comment clarifying that `Future.cancel()` cannot stop an
    already-running thread — it only drops queued work — so pool bounding
    matters even with timeouts.
  - Added an **Observability** section with saturation + rejection metrics
    you should export from every bulkhead.
- Re-ran both notebooks end-to-end; outputs saved in place.
