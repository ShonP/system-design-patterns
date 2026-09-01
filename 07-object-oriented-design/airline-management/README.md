# Airline Management

> Part of the `07-object-oriented-design/` series. Includes runnable notebooks and references.

## Overview

OOD of a flight booking platform: aircraft, flights, seats with class, bookings.

## Concepts covered

- Flight / Aircraft / Seat modelling; per-flight seat availability
- SeatClass as an enum + pricing table (avoid subclass explosion)
- Subclass for *behaviour*, enum for *data* -- and how to tell them apart
- **Strategy** -- injectable `RefundPolicy` instead of a hard-coded refund table
- Invariant enforcement: `Booking.mark_cancelled()`, `Flight.assign_crew()`
- Booking and ticket generation; a check-then-act race and the lock that fixes it

## Setup

```bash
cd 07-object-oriented-design/airline-management
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
