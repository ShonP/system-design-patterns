# Retry

> Part of the `05-microservices/` series. Includes runnable notebooks and references.

## Overview

Retrying transient failures — safely.

## Concepts covered

- Bad → best retry strategies (immediate, fixed, exponential, +jitter)
- Thundering herd and why jitter fixes it
- Error classification (retryable vs terminal)
- `Retry-After` headers, deadlines, per-attempt timeouts
- Retry budgets to prevent storms
- Idempotency keys for safe `POST` retries
- How retry composes with circuit breaker and bulkhead

## Setup

```bash
cd 05-microservices/retry
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_introduction.ipynb`](./notebooks/01_introduction.ipynb) -- Retry strategies, bad → best
- [`notebooks/02_worked_example.ipynb`](./notebooks/02_worked_example.ipynb) -- Thundering herd and how jitter fixes it
- [`notebooks/03_real_world_patterns.ipynb`](./notebooks/03_real_world_patterns.ipynb) -- Error classification, `Retry-After`, deadlines, retry budget, idempotency keys

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
