# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Observability (Metrics, Logs, Traces)` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added notebooks 01–03 (three pillars, SLI/SLO/SLA, mini metrics collector).
- **QA pass**: rewrote NB1 with a bad-vs-good logging progression and a shared `trace_id` correlation demo; expanded NB2 with vanity vs user-visible SLIs, the RED/USE methods, and a fast/slow burn-rate example; expanded NB3 with labels, a cardinality-explosion anti-pattern, and a Prometheus-style **bucketed histogram** (cumulative buckets + `_sum`/`_count` + interpolated quantiles). Replaced private `_samples` access with public accessors.
- Added NB4 `04_debugging_an_outage.ipynb` — capstone running an instrumented "checkout" service through an alert → trace → log investigation.
- Verified all four notebooks execute cleanly via `jupyter nbconvert --execute`.
