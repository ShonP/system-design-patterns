# Event Driven Architecture

> Part of the `05-microservices/` series. Includes runnable notebooks and references.

## Overview

Building services that communicate via events.

## Concepts covered

- Event types (facts vs commands)
- Brokers and topics
- Schema evolution

## Setup

```bash
cd 05-microservices/event-driven-architecture
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_introduction.ipynb`](./notebooks/01_introduction.ipynb) -- Events vs. requests
- [`notebooks/02_worked_example.ipynb`](./notebooks/02_worked_example.ipynb) -- A tiny in-memory event bus showing loose coupling

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
