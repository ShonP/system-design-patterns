# Circuit Breaker

> Part of the `05-microservices/` series. Includes runnable notebooks and references.

## Overview

Fail fast when a downstream dependency is unhealthy.

## Concepts covered

- Closed, open, half-open states
- Thresholds and reset timers
- Fallbacks

## Setup

```bash
cd 05-microservices/circuit-breaker
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_introduction.ipynb`](./notebooks/01_introduction.ipynb) -- CLOSED / OPEN / HALF_OPEN state machine
- [`notebooks/02_worked_example.ipynb`](./notebooks/02_worked_example.ipynb) -- Cascading failure prevention -- measured

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
