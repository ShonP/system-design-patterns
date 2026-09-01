# Airbnb

> Part of `06-system-designs/`. Runnable notebooks + references.

## Overview

Property rental marketplace: search, booking, availability calendar.

## Concepts covered

- Two-sided marketplace requirements (functional + non-functional)
- Back-of-envelope sizing: search QPS, index size, dense vs sparse availability rows
- Availability calendar: why a sparse per-night table makes double-booking *structurally* impossible
- **Runnable double-booking race**: five threads, five *overlapping* date ranges, real
  per-thread SQLite connections, no application-level lock — the database is the only arbiter
- Geo search: linear scan → grid buckets (verified against the scan) → S2/H3
- Cache-aside with single-flight to survive a stampede
- Token-bucket rate limiting

## Setup

```bash
cd 06-system-designs/airbnb
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
