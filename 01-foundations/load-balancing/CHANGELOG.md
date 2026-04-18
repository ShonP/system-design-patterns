# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18 (QA review)
- Notebook 1: added an L4 vs L7 explainer cell.
- Notebook 2: simulator now records every per-request latency; replaced the
  misleading `stats()` (which previously labelled "P95" but returned a per-
  backend average) with real avg/p50/p95/p99 percentiles. Added the
  **power-of-two-choices** algorithm (capacity-weighted) and updated the chart
  to show avg vs p95.
- Notebook 3: switched `StickyLB` from Python's process-randomized `hash()`
  to a deterministic `hashlib.md5` so the sticky mapping survives restarts.
- Notebook 4 **(new)**: consistent hashing — naive `hash % N` failure demo,
  hash ring with virtual nodes, remap-rate comparison, vnode tuning.
- README: refreshed intro, added Notebook 4 to the table.

## 2026-04-18
- Scaffolded `Load Balancing` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
