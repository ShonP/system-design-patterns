# Notification System

> Part of the `06-system-designs/` series. Includes runnable notebooks and references.

## Overview

Scalable push / email / SMS notifications with priority, retries, and idempotency.

## Concepts covered

- Capacity math that confronts the per-provider caps: with a realistic channel mix the SMS
  provider limit is exceeded **even at sustained load**, which is what forces the queue
- Priority queues with starvation protection — strict priority is shown genuinely starving
  lower levels under a continuous high-priority stream, then weighted round-robin fixing it
  (and what that costs high priority)
- Exponential backoff, **full jitter** (demonstrated on a 1,000-worker fleet, not one client),
  and a DLQ that actually receives messages
- **At-least-once delivery**: a worker crash between "call the provider" and "ack the queue"
  produces a real duplicate notification, which is then killed by a delivery-side dedup guard
  — and why front-door `dedup_key` idempotency does *not* catch it
- Fan-out both ways: one event → many channels, and one event → millions of users in batches
- Per-provider token buckets, circuit breakers, and the metrics you must have

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
