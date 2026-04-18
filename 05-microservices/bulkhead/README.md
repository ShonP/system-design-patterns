# Bulkhead

> Part of the `05-microservices/` series. Includes runnable notebooks and references.

## Overview

Isolate pools of resources so one failure does not sink the ship.

## Concepts covered

- Thread/connection pool partitioning
- Tenant isolation
- Failure containment

## Setup

```bash
cd 05-microservices/bulkhead
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_introduction.ipynb`](./notebooks/01_introduction.ipynb) -- Thread-pool isolation between downstreams
- [`notebooks/02_worked_example.ipynb`](./notebooks/02_worked_example.ipynb) -- Payments vs. recommendations, one slow one fine

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
