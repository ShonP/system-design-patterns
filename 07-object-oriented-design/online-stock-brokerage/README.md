# Online Stock Brokerage

> Part of the `07-object-oriented-design/` series. Includes runnable notebooks and references.

## Overview

OOD of a brokerage: accounts, portfolios, market/limit/stop orders, and a toy exchange.

## Concepts covered

- Account / Portfolio / Position model
- Order polymorphism (Market / Limit / Stop)
- Trade recording
- Simplified matching engine

## Setup

```bash
cd 07-object-oriented-design/online-stock-brokerage
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_class_design.ipynb`](./notebooks/01_class_design.ipynb) — Domain model, bad `if/elif` vs clean polymorphism
- [`notebooks/02_implementation.ipynb`](./notebooks/02_implementation.ipynb) — Working Python brokerage: orders, cancel, stop-loss
- [`notebooks/03_patterns_and_matching.ipynb`](./notebooks/03_patterns_and_matching.ipynb) — Price-time priority order book, Observer, Decorator risk guards

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
