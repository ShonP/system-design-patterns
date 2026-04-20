# Parking Lot

> Part of the `07-object-oriented-design/` series. Includes runnable notebooks and references.

## Overview

Classic OOD interview — a parking-lot system.

## Concepts covered

- Requirements, actors, and use-cases
- Class design + UML-style diagram
- SOLID principles applied to a concrete problem
- **Bad → good → best** refactor (God class → OOD → Strategy pattern)
- Thread safety / concurrency (race reproduction + lock fix)
- Reserved spots via a composable `SpotRule` hierarchy
- Pluggable payment providers (cash / card / mock)

## Setup

```bash
cd 07-object-oriented-design/parking-lot
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_class_design.ipynb`](./notebooks/01_class_design.ipynb) — requirements, actors, UML-style class diagram, SOLID checklist
- [`notebooks/02_implementation.ipynb`](./notebooks/02_implementation.ipynb) — **bad → good → best** walkthrough (God class → OOD → Strategy pattern) with assertions
- [`notebooks/03_extensions.ipynb`](./notebooks/03_extensions.ipynb) — concurrency (race + lock), reserved/EV spots, pluggable payments

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
