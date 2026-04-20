# Stock Exchange

> Part of `06-system-designs/`. Runnable notebooks + references.

## Overview

Stock trading: order book, matching engine, market data.

## Concepts covered

- Limit order book mechanics with **price-time priority**
- Matching engine: naive scan → price-level FIFO queues (bad→best)
- Why matching is **single-threaded** (determinism demo)
- **Integer ticks**, not floats, for money
- Data validation with `pydantic` + `client_order_id` idempotency
- Order types: `limit`, `market`, `IOC`, `FOK`
- WAL + replay for crash recovery
- Market-data fan-out off the matcher's hot path

## Setup

```bash
cd 06-system-designs/stock-exchange
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_requirements_and_architecture.ipynb`](./notebooks/01_requirements_and_architecture.ipynb) — Requirements & Architecture
- [`notebooks/02_data_and_api.ipynb`](./notebooks/02_data_and_api.ipynb) — Data Model & APIs
- [`notebooks/03_deep_dive.ipynb`](./notebooks/03_deep_dive.ipynb) — Deep Dive (runnable code)

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
