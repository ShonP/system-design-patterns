# Strangler

> Part of the `05-microservices/` series. Includes runnable notebooks and references.

## Overview

Incrementally replacing a legacy system.

## Concepts covered

- Fig pattern
- Facade / routing layer
- Migration playbook

## Setup

```bash
cd 05-microservices/strangler
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_introduction.ipynb`](./notebooks/01_introduction.ipynb) — Why big-bang rewrites fail, the strangler fig metaphor, facade routing by path, picking your first slice, real-world stories (Amazon, Shopify, Netflix, GitHub).
- [`notebooks/02_worked_example.ipynb`](./notebooks/02_worked_example.ipynb) — Canary routing by percentage, dark launch / shadow traffic (GitHub's Scientist pattern), kill switches and instant rollback, a pre-ramp production checklist.
- [`notebooks/03_end_to_end_banking.ipynb`](./notebooks/03_end_to_end_banking.ipynb) — Full worked example: strangling a banking monolith through 5 phases with dual-write data migration, per-endpoint progress tracking, and retirement.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
