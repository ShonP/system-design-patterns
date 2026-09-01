# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Hotel Management` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_class_design.ipynb, 02_implementation.ipynb.

## 2026-04-20
- Rewrote both notebooks with a bad → better → best progression.
- `01_class_design.ipynb`: added three design attempts (dicts, coupled classes,
  clean `Enum` + `@dataclass` + computed properties) with runnable code,
  explanations, and exercises.
- `02_implementation.ipynb`: added `ReservationStatus` / `RoomStatus` enums,
  24-hour cancellation refund policy, check-in/check-out lifecycle,
  housekeeping log, room-service extras, and a printed invoice — showing a
  realistic end-to-end hotel day.
- Verified with `uv run jupyter nbconvert --execute` (both notebooks run clean).
- Added `03_polymorphism_and_patterns.ipynb`: Strategy pattern for pricing
  (composable via Decorator), Factory for room construction from config,
  Observer for booking notifications, plus explicit SOLID framing
  (Open/Closed, Dependency Inversion). Runs clean via nbconvert.

## 2026-08-20
- QA pass: re-verified every notebook executes end to end with
  `uv run jupyter nbconvert --execute`; normalized the kernelspec to
  `Python 3 (.venv)` and stripped saved outputs.
- Fixed `Hotel.is_available`: it read only `MAINTENANCE`, so `NEEDS_CLEAN` was dead state
  and the notebook's claim that housekeeping prevents same-day turnover was false.
  Dirty rooms are now unsellable until `complete_housekeeping`, demonstrated in the walkthrough.
- Fixed reservation ids: `_rid` was a class attribute shared by every `Hotel` instance, so a
  second hotel's first reservation was not #1. Now per-instance (notebooks 2 and 3).
- Added invariant cells to notebook 2 (date validation, half-open overlap, cancel/refund
  boundary, lifecycle state machine, derived billing) and to notebook 3 (Strategy swap,
  Decorator composition order, Factory validation, late-subscribing Observer).
