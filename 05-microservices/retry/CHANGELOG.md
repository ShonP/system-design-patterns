# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Retry` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_introduction.ipynb, 02_worked_example.ipynb.

## 2026-04-19
- Reworked `01_introduction.ipynb` as an explicit bad → best progression with
  runnable demos for each strategy, a capped exponential helper, and a
  full-jitter helper.
- Added `03_real_world_patterns.ipynb` covering error classification
  (retryable vs terminal), `Retry-After` header, overall deadlines, retry
  budgets, idempotency keys, and how retry composes with circuit breaker and
  bulkhead. All examples run offline using only the stdlib.
- README: expanded concepts list and added link to the new notebook.
- Rewrote `02_worked_example.ipynb` for a clearer thundering-herd demo:
  added a peak-concurrency metric, ASCII histograms, a scale sweep
  (10 / 100 / 1000 clients) showing up to 3.5× peak reduction from jitter,
  and switched the demo to full-jitter to match the recommendation.
- Extended `03_real_world_patterns.ipynb` with two new sections:
  a **per-attempt timeout** demo (threaded wrapper, then retry) and
  a **jitter variants** comparison table (no / equal / full / decorrelated).
- Normalized cell IDs on notebook 2 to silence nbformat warning.
