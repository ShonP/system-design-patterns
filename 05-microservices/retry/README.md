# Retry

> Part of the `05-microservices/` series. Includes runnable notebooks and references.

## Overview

Retrying transient failures — safely.

## Concepts covered

- Backoff and jitter
- Retry budgets
- Idempotency as a prerequisite

## Setup

```bash
cd 05-microservices/retry
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_introduction.ipynb`](./notebooks/01_introduction.ipynb) -- Retry strategies: fixed, exponential, jitter
- [`notebooks/02_worked_example.ipynb`](./notebooks/02_worked_example.ipynb) -- Thundering herd and how jitter fixes it

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
