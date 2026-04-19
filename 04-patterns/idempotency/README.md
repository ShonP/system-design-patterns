# Idempotency

> Part of `04-patterns/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Overview

Making operations safe to retry.

## Concepts covered

- Idempotency keys
- At-least-once vs exactly-once
- Replay protection
- Deduplication stores

## Setup

```bash
cd 04-patterns/idempotency
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_double_charge.ipynb`](./notebooks/01_double_charge.ipynb) — the classic retry-causes-double-charge bug, plus which HTTP methods are idempotent.
- [`notebooks/02_idempotency_keys.ipynb`](./notebooks/02_idempotency_keys.ipynb) — server-side replay cache keyed on a client UUID, including request-body fingerprinting to reject key reuse with a different body.
- [`notebooks/03_database_dedup.ipynb`](./notebooks/03_database_dedup.ipynb) — exactly-once *effect* via `UNIQUE` constraint inside the same transaction (SQLite, no extra services), with a crash simulation and TTL cleanup.
- [`notebooks/04_concurrent_retries.ipynb`](./notebooks/04_concurrent_retries.ipynb) — race conditions from concurrent retries and how an atomic `INSERT` + `IN_PROGRESS` marker fixes them. Includes a table of real-world implementations (Stripe, AWS SQS FIFO, Kafka, PayPal, GitHub).

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
