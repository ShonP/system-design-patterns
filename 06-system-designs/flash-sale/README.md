# Flash Sale

> Part of the `06-system-designs/` series. Includes runnable notebooks and references.

## Overview

Handling a short window of massive concurrency without overselling.

## Concepts covered

- Back-of-the-envelope sizing for spike traffic
- Waiting-room pattern at the edge
- Token-bucket rate limiting
- Atomic stock reservation via Redis / Lua (simulated)
- **Hot-key sharding** for stock counters
- Bounded admission queue for backpressure
- Reserve-now-pay-later flow with TTL + reaper
- Idempotency keys for safe client retries
- Bad → best progression: naive → locked → atomic CAS → full path

## Setup

```bash
cd 06-system-designs/flash-sale
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_requirements_and_architecture.ipynb`](./notebooks/01_requirements_and_architecture.ipynb) — Requirements & Architecture
- [`notebooks/02_data_and_api.ipynb`](./notebooks/02_data_and_api.ipynb) — Data Model & APIs
- [`notebooks/03_deep_dive.ipynb`](./notebooks/03_deep_dive.ipynb) — Deep Dive: Atomic stock, rate limit, admission queue

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
