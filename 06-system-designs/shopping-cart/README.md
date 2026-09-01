# Shopping Cart

> Part of `06-system-designs/`. Runnable notebooks + references.

## Overview

E-commerce cart: inventory reservation, checkout, payment.

## Concepts covered

- Back-of-envelope: read:write ratio, and the hydration fan-out that forces a cache
- Cart state: client vs server; slim cart + hydrate on read
- **Concurrent updates from two devices** — the Dynamo lost-update, reproduced
  and then fixed four ways: conditional write, per-item atomic `ADD`,
  version-vector siblings (and the resurrected-deleted-item anomaly), and a
  PN-Counter CRDT cart. With the honest comparison table for which to ship.
- Inventory reservation with TTL
- Checkout saga (cart → payment → order)
- Guest → user cart merge: idempotent by `merge_id`, plus the crash window that
  double-counts a naive implementation
- TTL & abandonment: the marketing clock vs the storage clock, why native TTL is
  garbage collection and not correctness, and read-time expiry filtering
- Idempotency keys

## Setup

```bash
cd 06-system-designs/shopping-cart
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
