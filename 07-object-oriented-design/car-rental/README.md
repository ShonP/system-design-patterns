# Car Rental

> Part of the `07-object-oriented-design/` series. Includes runnable notebooks and references.

## Overview

OOD of a car rental service: vehicles, reservations with a state machine, and availability search.

## Concepts covered

- Vehicle class hierarchy with polymorphic rates
- Reservation state machine (pending → confirmed → active → returned / cancelled)
- Availability via overlapping-date checks (with the boundary cases asserted)
- **Strategy** -- `PricingPolicy`: flat vs weekend-surcharge + weekly-discount
- **Factory** -- `VehicleFactory` registry turns fleet data rows into subclasses
- Invariants in constructors (`end` may not precede `start`)
- Payments with their own charge / refund state, plus late-return fees

## Setup

```bash
cd 07-object-oriented-design/car-rental
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
