# Bff

> Part of the `05-microservices/` series. Includes runnable notebooks and references.

## Overview

Backend-for-Frontend — one gateway per client type.

## Concepts covered

- Why one-size-fits-all gateways break
- Per-client aggregation
- Ownership and team boundaries

## Setup

```bash
cd 05-microservices/bff
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_introduction.ipynb`](./notebooks/01_introduction.ipynb) -- What is a BFF -- one gateway per client type
- [`notebooks/02_worked_example.ipynb`](./notebooks/02_worked_example.ipynb) -- Monolith API vs. BFF: measured latency and bytes

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
