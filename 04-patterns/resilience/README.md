# Resilience

> Part of `04-patterns/`. Five runnable notebooks walk from a naïve baseline to a fully stacked resilience pipeline, one pattern at a time.

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

- [`notebooks/01_retry_with_backoff.ipynb`](./notebooks/01_retry_with_backoff.ipynb) — naive → exponential → exponential + jitter (AWS recipe), with a matplotlib visualization of the thundering-herd effect.
- [`notebooks/02_circuit_breaker.ipynb`](./notebooks/02_circuit_breaker.ipynb) — CLOSED → OPEN → HALF_OPEN; fail-fast when downstream is dead, with a BAD "keep hammering" baseline for contrast.
- [`notebooks/03_bulkhead.ipynb`](./notebooks/03_bulkhead.ipynb) — per-dependency thread pools (and an `asyncio.Semaphore` equivalent) so one slow caller can't starve everyone else.
- [`notebooks/04_timeouts_and_graceful_degradation.ipynb`](./notebooks/04_timeouts_and_graceful_degradation.ipynb) — hard timeouts, fallback to defaults / stale cache, and feature-flag kill switches; ends with a diagram showing how all the patterns stack.
- [`notebooks/05_stacking_all_patterns.ipynb`](./notebooks/05_stacking_all_patterns.ipynb) — **capstone**: timeout + retry-with-jitter + thread-safe circuit breaker + bounded-semaphore bulkhead + fallback, composed into one request pipeline with a naive baseline for contrast.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
