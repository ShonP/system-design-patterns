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
