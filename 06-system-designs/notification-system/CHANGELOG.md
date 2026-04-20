# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Notification System` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added notebooks 01-03.

## 2026-04-20
- Expanded all three existing notebooks with more explanation and runnable code:
  - `01_requirements_and_architecture.ipynb`: added functional/non-functional tables, back-of-envelope capacity calc, trade-off table.
  - `02_data_and_api.ipynb`: added SQLite schema, Pydantic validation example, and an end-to-end mini pipeline (render -> prefs -> dedup -> log -> deliver).
  - `03_deep_dive.ipynb`: restructured each section as **bad -> better -> best** (single FIFO -> strict priority -> weighted round-robin; tight loop -> exp backoff -> exp+jitter+DLQ; none -> payload hash -> dedup key + TTL).
- Added `04_production_concerns.ipynb`: fan-out across channels, per-provider token-bucket rate limiting, circuit breaker state machine, observability/metrics.
- All notebooks executed end-to-end to verify they run cleanly.
