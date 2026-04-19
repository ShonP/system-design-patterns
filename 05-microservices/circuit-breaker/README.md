# Circuit Breaker

> Part of the `05-microservices/` series. Includes runnable notebooks and references.

## Overview

Fail fast when a downstream dependency is unhealthy.

## Concepts covered

- Closed, open, half-open states
- Thresholds, cool-down timers, rolling failure windows
- Thread-safe state transitions
- Fallbacks (cache / default / degraded UX)
- Combining with retry and backoff (and why order matters)
- Observability: metrics on state transitions
- Production libraries (pybreaker, Resilience4j, Polly, gobreaker, Istio)

## Setup

```bash
cd 05-microservices/circuit-breaker
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_introduction.ipynb`](./notebooks/01_introduction.ipynb) — bad → best progression: no breaker, naive counter, classic CLOSED/OPEN/HALF_OPEN, windowed + thread-safe
- [`notebooks/02_worked_example.ipynb`](./notebooks/02_worked_example.ipynb) — cascading failure under load (with latency metrics) + fallback demo
- [`notebooks/03_real_world_patterns.ipynb`](./notebooks/03_real_world_patterns.ipynb) — retry + breaker ordering, observability, production libraries

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
