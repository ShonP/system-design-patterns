# Saga

> Part of the `05-microservices/` series. Includes runnable notebooks and references.

## Overview

Multi-service transactions without 2PC.

## Concepts covered

- Orchestration vs choreography
- Compensating actions
- Failure scenarios

## Setup

```bash
cd 05-microservices/saga
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_introduction.ipynb`](./notebooks/01_introduction.ipynb) -- Distributed transactions without 2PC
- [`notebooks/02_choreography_vs_orchestration.ipynb`](./notebooks/02_choreography_vs_orchestration.ipynb) -- Two saga styles compared
- [`notebooks/03_compensation_on_failure.ipynb`](./notebooks/03_compensation_on_failure.ipynb) -- Compensating actions when a step fails

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
