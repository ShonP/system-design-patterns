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

- [`notebooks/01_introduction.ipynb`](./notebooks/01_introduction.ipynb) -- What is a BFF: mobile/web/TV payloads side-by-side
- [`notebooks/02_worked_example.ipynb`](./notebooks/02_worked_example.ipynb) -- Universal API vs. BFF: parallel fan-out, graceful degradation, tiny cache -- with measured latency
- [`notebooks/03_bff_vs_gateway_and_pitfalls.ipynb`](./notebooks/03_bff_vs_gateway_and_pitfalls.ipynb) -- BFF vs. API Gateway, classic pitfalls, when NOT to use a BFF, review checklist

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
