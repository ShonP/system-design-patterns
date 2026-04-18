# Resilience

> Part of `04-patterns/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Overview

Keeping services healthy under partial failure.

## Concepts covered

- Retries with backoff and jitter
- Circuit breakers
- Bulkheads and isolation
- Graceful degradation

## Setup

```bash
cd 04-patterns/resilience
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_retry_with_backoff.ipynb`](./notebooks/01_retry_with_backoff.ipynb) — naive → exponential → exponential + jitter (AWS recipe).
- [`notebooks/02_circuit_breaker.ipynb`](./notebooks/02_circuit_breaker.ipynb) — CLOSED → OPEN → HALF_OPEN; fail-fast when downstream is dead.
- [`notebooks/03_bulkhead.ipynb`](./notebooks/03_bulkhead.ipynb) — per-dependency thread pools so one slow caller can't starve everyone else.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
