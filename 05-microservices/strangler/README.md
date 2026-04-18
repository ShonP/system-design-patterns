# Strangler

> Part of the `05-microservices/` series. Includes runnable notebooks and references.

## Overview

Incrementally replacing a legacy system.

## Concepts covered

- Fig pattern
- Facade / routing layer
- Migration playbook

## Setup

```bash
cd 05-microservices/strangler
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_introduction.ipynb`](./notebooks/01_introduction.ipynb) -- Strangler fig for legacy migration
- [`notebooks/02_worked_example.ipynb`](./notebooks/02_worked_example.ipynb) -- Routing traffic gradually from old to new

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
