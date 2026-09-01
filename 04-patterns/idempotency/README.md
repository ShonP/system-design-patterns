# Idempotency

> Part of `04-patterns/`. Four runnable notebooks: the bug, the key, the durable store, and the concurrency edge cases that break naive implementations.

## Overview

Making operations safe to retry.

## Concepts covered

- Natural idempotency (end-state operations) vs key-based idempotency (delta operations)
- Idempotency keys: replaying the stored **response**, not just skipping the work
- Request-body fingerprinting, and scoping keys per caller
- At-least-once vs exactly-once *delivery* vs exactly-once *effect*
- Side effect + dedup record in one transaction (the crash window)
- Atomic claims under concurrent retries, and leases for crashed workers
- TTL / retention, and what the whole pattern costs

## Setup

```bash
cd 04-patterns/idempotency
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_double_charge.ipynb`](./notebooks/01_double_charge.ipynb) — the classic retry-causes-double-charge bug, then a runnable comparison of naturally idempotent (end-state) operations against delta operations, so you can tell when you need a key at all.
- [`notebooks/02_idempotency_keys.ipynb`](./notebooks/02_idempotency_keys.ipynb) — server-side replay cache keyed on a client UUID; body fingerprinting to reject key reuse with a different body (`400`), and per-caller scoping to stop one client from reading another's cached response.
- [`notebooks/03_database_dedup.ipynb`](./notebooks/03_database_dedup.ipynb) — exactly-once *effect* via `UNIQUE` constraint inside the same transaction (SQLite, no extra services), with a crash simulation and TTL cleanup.
- [`notebooks/04_concurrent_retries.ipynb`](./notebooks/04_concurrent_retries.ipynb) — concurrent duplicates: the check-then-act race, the atomic `INSERT` + `IN_PROGRESS` claim that fixes it, and the wedged-claim failure the claim itself introduces (fixed with a lease). Ends with when to use each mechanism, when you need none of them, and what the pattern costs. Includes a table of real-world implementations (Stripe, AWS SQS FIFO, Kafka, PayPal, GitHub).

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
