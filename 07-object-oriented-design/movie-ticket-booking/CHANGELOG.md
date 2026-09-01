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

## 2026-08-20
- QA pass: re-verified every notebook executes end to end with
  `uv run jupyter nbconvert --execute`; normalized the kernelspec to
  `Python 3 (.venv)` and stripped saved outputs.
- Added a "verify the design" cell proving the invariant the lab claims: under 30 concurrent
  threads exactly one booking wins a seat, all-or-nothing multi-seat batches leave no partial
  hold, holds cannot be stolen or confirmed after expiry, and BOOKED is terminal. The same
  test is run against `NaiveBookingService` and asserted to FAIL, so the lock is proven to
  do real work.
- Explained why the race reproduces deterministically (`time.sleep` releases the GIL) and
  why it would still be a bug without the sleep.
- Rewrote the README's two-bullet "Concepts covered" to match what the notebooks teach.
