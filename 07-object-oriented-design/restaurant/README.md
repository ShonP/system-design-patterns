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

- [`notebooks/01_class_design.ipynb`](./notebooks/01_class_design.ipynb) — Domain model and class relationships
- [`notebooks/02_implementation.ipynb`](./notebooks/02_implementation.ipynb) — Working Python implementation you can run

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
