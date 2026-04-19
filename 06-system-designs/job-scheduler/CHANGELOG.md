# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Fixed a bug in notebook 3 where the DLQ demo used synthetic UUIDs that were
  not present in the `executions` / `jobs` tables, causing a foreign key
  violation. The demo now inserts real rows first.
- Fixed a `cursor_factory` TypeError in notebook 3's DLQ helpers
  (`conn.cursor(psycopg2.extras.RealDictCursor)` -> `cursor_factory=...`).
- Notebook 1: added a runnable "bad vs best" comparison that benchmarks naive
  Postgres polling (`SELECT ... UPDATE`) against a Redis ZSET (`ZPOPMIN`).
- Notebook 3: added a "Real-World Systems & Operational Concerns" section
  covering Celery / Sidekiq / Airflow / EventBridge / Temporal mapping,
  singleton-watcher leader election, the `SKIP LOCKED` alternative, and
  production observability checklist.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
