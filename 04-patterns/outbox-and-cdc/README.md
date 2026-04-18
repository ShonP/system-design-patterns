# Outbox And Cdc

> Part of `04-patterns/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Overview

Reliably publishing events from an OLTP database.

## Concepts covered

- Transactional outbox
- Change Data Capture (CDC)
- Log-based vs query-based CDC
- Ordering and deduplication

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

- [`notebooks/01_dual_write_problem.ipynb`](./notebooks/01_dual_write_problem.ipynb) — DB committed, message bus never published — silent inconsistency.
- [`notebooks/02_transactional_outbox.ipynb`](./notebooks/02_transactional_outbox.ipynb) — write the event into an `outbox` table inside the same transaction; polling publisher with `FOR UPDATE SKIP LOCKED`.
- [`notebooks/03_polling_vs_cdc.ipynb`](./notebooks/03_polling_vs_cdc.ipynb) — replace polling with logical replication slots (the same trick Debezium uses).

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
