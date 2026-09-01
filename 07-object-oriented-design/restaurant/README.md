# Restaurant

> Part of the `07-object-oriented-design/` series. Includes runnable notebooks and references.

## Overview

OOD of a restaurant POS: menu, tables, orders, and billing.

## Concepts covered

- Menu and MenuItem modeling
- Table state (free/taken/reserved)
- Order lifecycle (open/placed/served/paid)
- Bill computation with tax & tip

## Setup

```bash
cd 07-object-oriented-design/restaurant
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_class_design.ipynb`](./notebooks/01_class_design.ipynb) — Bad (god class) → good domain model; state machines; SOLID tour
- [`notebooks/02_implementation.ipynb`](./notebooks/02_implementation.ipynb) — Runnable Python: `MenuItem`, `Table`, `Order`, `Bill`, `Staff`, `Kitchen`, `Reservation` + end-to-end dinner demo
- [`notebooks/03_polymorphism_and_patterns.ipynb`](./notebooks/03_polymorphism_and_patterns.ipynb) — **Strategy** (pricing / happy-hour / loyalty, composable and applied *pre-tax*), **Factory** (menu from JSON), **Observer** (kitchen, SMS, manager dashboard, with an injected event hub)

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
