# Library Management

> Part of the `07-object-oriented-design/` series. Includes runnable notebooks and references.

## Overview

Object-oriented design of a library management system, taught as a **bad → better → best** progression so you can feel why good design matters.

## Concepts covered

- Domain modeling: `Book`, `BookItem`, `Member`, `Loan`, `Reservation`
- Single Responsibility Principle (god class → separated classes)
- Strategy pattern (pluggable `FineCalculator`)
- Observer pattern: `Library` owns a subscriber list (`subscribe` / `unsubscribe` / `_publish`), so a notifier and an audit log can both listen
- Strategy vs. Observer — why `FineCalculator` is one and `LibraryObserver` is the other
- In-memory `Catalog` search (title / author / subject)
- Reservation queue (FIFO) with auto-notify on return
- Edge cases: loan limits (enforced *and* asserted), unknown ISBN/member, on-time returns, FIFO queue-jumping
- Named limitations: reservations never expire; `Member.active_loans` is per-object, so one `Member` must not be shared across two `Library` instances

## Setup

```bash
cd 07-object-oriented-design/library-management
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_class_design.ipynb`](./notebooks/01_class_design.ipynb) -- bad → better → best class design
- [`notebooks/02_implementation.ipynb`](./notebooks/02_implementation.ipynb) -- full runnable system: search, borrow, reserve, return, fines, notifications

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
