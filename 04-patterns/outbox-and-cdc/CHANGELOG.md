# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19 (review pass)
- `03_polling_vs_cdc.ipynb`: added a runnable peek-vs-get demo (two `peek_changes` calls return the same rows, then `get_changes` advances the slot) so the "peek lets you ack the sink before advancing" claim is actually shown, not just described.
- `04_gotchas.ipynb`: added a runnable idempotent-consumer demo using a `processed_events(event_id PRIMARY KEY)` table inside the same transaction as the side-effect, showing that a redelivered event does not double-apply.

## 2026-04-19
- Expanded `01_dual_write_problem.ipynb` to show three failed attempts (DB-first, publish-first, retry loop) plus real-world failure examples, and added a "Why not 2PC?" aside.
- Rewrote `02_transactional_outbox.ipynb` with `event_id` UUIDs, `aggregate_id` for partitioning, a partial index, rollback-safety demo, consumer-side idempotency demo, and retention discussion.
- Hardened `03_polling_vs_cdc.ipynb`: idempotent slot creation, slot-lag monitoring, slot cleanup, peek-vs-get semantics, and notes on Debezium output plugins (`pgoutput`, `wal2json`).
- Added `04_gotchas.ipynb` covering per-entity ordering, poison-message dead-lettering, schema evolution (`schema_version`), and why exactly-once is a lie.

## 2026-04-18
- Scaffolded `Outbox And Cdc` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
