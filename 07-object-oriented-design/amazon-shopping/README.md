# Amazon Shopping

> Part of the `07-object-oriented-design/` series. Includes runnable notebooks and references.

## Overview

OOD of an Amazon-style online store.

## Concepts covered

- God class -> split responsibilities (bad -> better -> best progression)
- `Product`, `Cart`, `Order`, `Store` with single responsibilities
- **Strategy** -- pluggable `PaymentMethod` and `Discount`
- **Observer** -- notifiers react to order status changes
- **State** -- a legal-transition table on `Order`
- Order as an immutable snapshot (prices frozen at checkout)
- Checkout as a transaction boundary: stock rolled back when a charge declines
- Shipping, tax and coupons; concurrency notes on check-then-deduct

## Setup

```bash
cd 07-object-oriented-design/amazon-shopping
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_class_design.ipynb`](./notebooks/01_class_design.ipynb) -- Product, Cart, Order, Payment
- [`notebooks/02_implementation.ipynb`](./notebooks/02_implementation.ipynb) -- v1 buggy -> v2 Strategy -> v3 Observer/State, plus a "verify the design" assertion cell

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
