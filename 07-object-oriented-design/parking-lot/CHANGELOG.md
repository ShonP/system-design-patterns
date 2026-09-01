# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Parking Lot` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_class_design.ipynb, 02_implementation.ipynb.

## 2026-04-20
- Expanded `01_class_design.ipynb` with clarifying questions, actors/use-cases,
  noun/verb identification, and a SOLID checklist.
- Rewrote `02_implementation.ipynb` as a **bad → good → best** progression:
  God-class anti-pattern → clean OOD → Strategy pattern for pricing, with
  runnable assertions.
- Added `03_extensions.ipynb`: reproduces a concurrency race and fixes it with
  a lock, adds composable `SpotRule`s (EV / handicapped), and a pluggable
  `PaymentProcessor` abstraction (cash / card / mock).
- Updated `README.md` concept list and notebook index.

## 2026-08-20
- QA pass: every notebook re-executed end to end and verified clean.
- Added invariant enforcement to the "good" design in `02_implementation.ipynb`:
  `Spot.park()` / `Spot.leave()` now refuse illegal transitions (double-parking a
  spot, parking an oversized vehicle, freeing an empty spot) and `Ticket` is
  single-use, so a driver cannot be charged twice.
- Turned `ParkingLot.leave()` into a **template method** (`leave` owns the
  invariants, `_fee` is the overridable seam). `BetterParkingLot` now overrides
  only `_fee` — the previous override of `leave()` silently dropped the guards,
  which is the inheritance trap the notebook now calls out explicitly.
- Made `PricingStrategy` return a consistent `float` and documented the return
  type as part of the interface contract.
- Converted the `01` sanity check into real assertions about the fit rule, and
  replaced the silent `try/except` in `02` with a `must_raise` helper that fails
  when nothing is raised.
- Added a "verify the design" cell to `03_extensions.ipynb` covering the lock,
  composite `SpotRule`s, and the "declined payment keeps the spot" rule.
- Notebook hygiene: kernelspec normalised to `Python 3 (.venv)`, saved outputs stripped.
