# Service Discovery

> Part of the `05-microservices/` series. Includes runnable notebooks and references.

## Overview

Finding healthy service instances at runtime.

## Concepts covered

- Client-side vs server-side discovery
- Registries (Consul, Eureka, DNS)
- Health checks and deregistration

## Setup

```bash
cd 05-microservices/service-discovery
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_introduction.ipynb`](./notebooks/01_introduction.ipynb) -- Why discovery + a tiny client-side registry
- [`notebooks/02_worked_example.ipynb`](./notebooks/02_worked_example.ipynb) -- Server-side router, heartbeats, failure handling

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
