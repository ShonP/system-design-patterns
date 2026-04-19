# Cqrs

> Part of the `05-microservices/` series. Includes runnable notebooks and references.

## Overview

Splitting read and write models for scalability and clarity.

## Concepts covered

- Command vs query models
- Eventual consistency between sides
- Materialised read views

## Setup

```bash
cd 05-microservices/cqrs
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_introduction.ipynb`](./notebooks/01_introduction.ipynb) — Bad → best: shared model vs. split read/write with a projection
- [`notebooks/02_event_sourced_example.ipynb`](./notebooks/02_event_sourced_example.ipynb) — Event-sourced write side, multiple projections, snapshots
- [`notebooks/03_when_to_use_and_tradeoffs.ipynb`](./notebooks/03_when_to_use_and_tradeoffs.ipynb) — When to use CQRS, eventual consistency demo, real-world store + analytics example

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
