# Movie Ticket Booking

> Part of the `07-object-oriented-design/` series. Includes runnable notebooks and references.

## Overview

OOD of a movie-ticket booking system.

## Concepts covered

- Nouns → classes, verbs → methods, applied to `Cinema` / `Screen` / `Show` / `Seat` / `Booking` / `Payment`
- Bad → best progression: from one `MovieSystem` god class to single-responsibility classes
- `SeatStatus` as a three-state machine (`FREE → HELD → BOOKED`) instead of booleans
- `@dataclass(frozen=True)` value objects (`Movie`, `User`) vs. mutable entities (`Seat`, `Booking`)
- A printable seat map so state changes are visible, not just asserted
- **Check-then-act is a race**: `NaiveBookingService` reproducibly double-books one seat across 20 threads
- Fixing it with `threading.Lock` — exactly one winner, proven by assertion
- Timed **holds** with expiry (`hold → confirm → BOOKED`, or expire back to `FREE`), like real ticket sites
- All-or-nothing multi-seat orders — a batch containing a taken seat leaves no partial hold
- Mapping the in-memory lock to production: DB row locks (`SELECT ... FOR UPDATE`), Redis `SET NX EX`, optimistic version columns
- Named open problems: idempotency keys, clock skew, per-seat vs. per-show lock granularity

## Setup

```bash
cd 07-object-oriented-design/movie-ticket-booking
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_class_design.ipynb`](./notebooks/01_class_design.ipynb) -- Classes: Cinema, Show, Seat, Booking
- [`notebooks/02_implementation.ipynb`](./notebooks/02_implementation.ipynb) -- Seat selection + concurrent booking

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
