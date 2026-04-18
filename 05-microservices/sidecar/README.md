# Sidecar

> Part of the `05-microservices/` series. Includes runnable notebooks and references.

## Overview

Out-of-process helper bundled with a service instance.

## Concepts covered

- Cross-cutting concerns (TLS, retries, telemetry)
- Service mesh data plane
- Upgrade and lifecycle

## Setup

```bash
cd 05-microservices/sidecar
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_introduction.ipynb`](./notebooks/01_introduction.ipynb) -- Sidecar pattern: cross-cutting concerns out of the app
- [`notebooks/02_worked_example.ipynb`](./notebooks/02_worked_example.ipynb) -- Sidecar as its own process via a local HTTP hop

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
