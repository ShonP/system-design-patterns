# Hotel Management

> Part of the `07-object-oriented-design/` series. Includes runnable notebooks and references.

## Overview

OOD of a hotel management system.

## Concepts covered

- Picking classes from requirements (nouns → classes, verbs → methods)
- Bad → better → best design progression
- `Enum` and `@dataclass` for typo-proof, low-boilerplate domain types
- Interval-overlap math for reservations and double-booking prevention
- State machines via `ReservationStatus` / `RoomStatus`
- Cancellation policy (24-hour refund rule) and housekeeping log
- Room service extras and a tiny invoice

## Setup

```bash
cd 07-object-oriented-design/hotel-management
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_class_design.ipynb`](./notebooks/01_class_design.ipynb) -- Classes: Hotel, Room, Reservation, Guest
- [`notebooks/02_implementation.ipynb`](./notebooks/02_implementation.ipynb) -- Booking flow with availability check

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
