# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Movie Ticket Booking` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_class_design.ipynb, 02_implementation.ipynb.

## 2026-04-20
- Rewrote `01_class_design.ipynb` with runnable code: bad "god class" anti-pattern,
  then single-responsibility classes (`Movie`, `Cinema`, `Screen`, `Show`, `Seat`,
  `User`, `Booking`, `Payment`), a printable seat-map demo, and a hands-on exercise.
- Rewrote `02_implementation.ipynb` with an explicit bad -> best progression:
  - v1 `NaiveBookingService` that reproduces the check-then-act race (20 winners).
  - v2 `SafeBookingService` using `threading.Lock` (exactly 1 winner, asserted).
  - v3 `HoldingBookingService` with timed holds, expiry, confirm and cancel.
- Added real-world mapping table (`threading.Lock` -> DB row lock -> Redis lock)
  and an edge-cases section (idempotency, clock skew, per-seat locking, payment failure).
- Verified both notebooks execute end to end with `uv run jupyter nbconvert --execute`.
