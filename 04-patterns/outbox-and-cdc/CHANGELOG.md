# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19
- Expanded `01_dual_write_problem.ipynb` to show three failed attempts (DB-first, publish-first, retry loop) plus real-world failure examples.
- Rewrote `02_transactional_outbox.ipynb` with `event_id` UUIDs, `aggregate_id` for partitioning, a partial index, rollback-safety demo, consumer-side idempotency demo, and retention discussion.
- Hardened `03_polling_vs_cdc.ipynb`: idempotent slot creation, slot-lag monitoring, slot cleanup, peek-vs-get semantics, and notes on Debezium output plugins (`pgoutput`, `wal2json`).
- Added `04_gotchas.ipynb` covering per-entity ordering, poison-message dead-lettering, schema evolution (`schema_version`), and why exactly-once is a lie.

## 2026-04-18
- Scaffolded `Outbox And Cdc` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
