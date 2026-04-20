# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Library Management` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_class_design.ipynb, 02_implementation.ipynb.

## 2026-04-20
- Rewrote both notebooks for depth and runnability:
  - `01_class_design.ipynb`: bad god-class → separated classes → SRP + Strategy + Observer design, with UML-style text diagram.
  - `02_implementation.ipynb`: full system with `Catalog` search, reservation queue (FIFO), pluggable `FineCalculator` (incl. student-discount variant), `Notifier` (observer), overdue sweep, and edge-case assertions.
- Verified end-to-end with `uv run jupyter nbconvert --execute`.
