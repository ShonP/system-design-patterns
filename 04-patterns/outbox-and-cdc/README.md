# Outbox And Cdc

> Part of `04-patterns/`. Four runnable notebooks that walk from a broken dual-write handler to a production-shaped outbox + CDC pipeline.

## Overview

Reliably publishing events from an OLTP database: when a service has to update a row *and* publish a message, how do you keep the two in sync across crashes and network blips?

## Concepts covered

- The dual-write problem (DB + message bus without a shared transaction)
- Transactional outbox (atomic DB write + event)
- Polling publisher with `FOR UPDATE SKIP LOCKED`
- At-least-once delivery and consumer-side idempotency (`event_id`)
- Change Data Capture (CDC) with Postgres logical replication slots
- Log-based vs query-based CDC, and the hybrid outbox + CDC pattern
- Per-entity ordering via `aggregate_id` (Kafka partition key)
- Production gotchas: poison messages / dead-letter, schema evolution, WAL retention

## Setup

Postgres + Adminer via Docker:

```bash
cd 04-patterns/outbox-and-cdc
docker compose up -d
uv sync
```

Browse the database at http://localhost:8080 (server=`postgres`, user=`demo`, password=`demo`, database=`outbox_demo`).

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_dual_write_problem.ipynb`](./notebooks/01_dual_write_problem.ipynb) — three failed attempts (DB-first, publish-first, retry loop) showing why dual writes are fundamentally broken.
- [`notebooks/02_transactional_outbox.ipynb`](./notebooks/02_transactional_outbox.ipynb) — transactional outbox with `event_id`/`aggregate_id`, polling publisher using `FOR UPDATE SKIP LOCKED`, consumer-side idempotency, and retention.
- [`notebooks/03_polling_vs_cdc.ipynb`](./notebooks/03_polling_vs_cdc.ipynb) — replace polling with Postgres logical replication slots (the same mechanism Debezium uses), including slot-lag monitoring and cleanup.
- [`notebooks/04_gotchas.ipynb`](./notebooks/04_gotchas.ipynb) — production gotchas: per-entity ordering, poison messages / dead-letter, schema evolution, and the "exactly-once is a lie" rule.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
