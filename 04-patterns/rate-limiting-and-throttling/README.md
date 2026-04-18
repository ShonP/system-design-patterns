# Rate Limiting And Throttling

> Part of `04-patterns/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Overview

Controlling request rates at the edge and between services.

## Concepts covered

- Token bucket vs leaky bucket
- Rate limiting vs throttling vs quotas
- Distributed counters
- Backpressure

## Setup

```bash
cd 04-patterns/rate-limiting-and-throttling
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_token_bucket.ipynb`](./notebooks/01_token_bucket.ipynb) — burst-tolerant limiter used by AWS / Stripe / NGINX.
- [`notebooks/02_leaky_bucket.ipynb`](./notebooks/02_leaky_bucket.ipynb) — paces traffic to a constant tempo for fragile downstreams.
- [`notebooks/03_sliding_window.ipynb`](./notebooks/03_sliding_window.ipynb) — fixed-window boundary burst vs sliding-window log; comparison table.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
