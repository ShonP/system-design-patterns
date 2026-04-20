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
