# Notification System

> Part of the `06-system-designs/` series. Includes runnable notebooks and references.

## Overview

Scalable push / email / SMS notifications with priority, retries, and idempotency.

## Concepts covered

- Priority queues with starvation protection
- Exponential backoff + jitter + DLQ
- Idempotency via dedup keys
- Per-channel worker pools

## Setup

```bash
cd 06-system-designs/notification-system
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_requirements_and_architecture.ipynb`](./notebooks/01_requirements_and_architecture.ipynb) — Requirements, capacity math & architecture
- [`notebooks/02_data_and_api.ipynb`](./notebooks/02_data_and_api.ipynb) — Data model, API contract & a runnable mini pipeline
- [`notebooks/03_deep_dive.ipynb`](./notebooks/03_deep_dive.ipynb) — Deep dive: priority, retries, idempotency (bad → better → best)
- [`notebooks/04_production_concerns.ipynb`](./notebooks/04_production_concerns.ipynb) — Fan-out, per-provider rate limiting, circuit breakers, metrics

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
