# Reminder / Alert

> Part of `06-system-designs/`. Runnable notebooks + references.

## Overview

Scheduling, delivery, timezone-aware reminders at scale.

## Concepts covered

- Requirements + back-of-envelope sizing (1B reminders, 100k fires/s peak)
- Data modelling: `Reminder` (intent) vs `Delivery` (attempt)
- Idempotency keys on `POST /reminders`
- Timezone-aware scheduling + DST-safe recurrence (daily/weekly/monthly)
- Scheduling algorithms, bad → best:
  1. Thread-per-reminder (why it fails)
  2. Polling loop over a sorted list
  3. `heapq` min-heap priority queue with lazy cancellation
  4. Hashed hierarchical time wheel
- At-least-once delivery + idempotent receivers
- Retries with exponential backoff + jitter; dead-letter queue
- Sharding strategies and SQL "hot ring" topology

## Setup

```bash
cd 06-system-designs/reminder-alert
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_requirements_and_architecture.ipynb`](./notebooks/01_requirements_and_architecture.ipynb) — Requirements & Architecture
- [`notebooks/02_data_and_api.ipynb`](./notebooks/02_data_and_api.ipynb) — Data Model & APIs
- [`notebooks/03_deep_dive.ipynb`](./notebooks/03_deep_dive.ipynb) — Deep Dive (runnable code)

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
