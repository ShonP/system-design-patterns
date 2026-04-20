# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Fixed `psycopg2.cursor(RealDictCursor)` bug in notebooks 02 and 03 (positional arg → `cursor_factory=` kwarg). Without the fix the cells crashed on first run.
- Made the NB1 metrics HTTP server cell idempotent so re-running it stops the previous server instead of raising `OSError: [Errno 48] Address already in use`.
- Made the NB2 alert-event demo cell idempotent (`TRUNCATE alert_events` before inserting) so re-runs produce the same result instead of piling up rows.
- Added a **cardinality explosion** concept + runnable demo to NB1 showing how `user_id` or `request_id` labels blow up series count and TSDB memory.
- Added the **Four Golden Signals** (Google SRE: Latency, Traffic, Errors, Saturation) to NB3 alongside the existing USE/RED methods.
- Added a **Real-World Examples** table to NB3 (Uber M3, Netflix Atlas, Thanos, Datadog, Grafana Mimir) with the common patterns they all share.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
