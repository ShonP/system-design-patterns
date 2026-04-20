# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Amazon Shopping` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_class_design.ipynb, 02_implementation.ipynb.

## 2026-04-20
- Expanded both notebooks with a clear bad -> best progression:
  - `01_class_design.ipynb`: added "God Class" anti-pattern, SRP discussion,
    responsibility table, design-patterns preview, and runnable enum/stub cell.
  - `02_implementation.ipynb`: rebuilt as v1 (buggy) -> v2 (Strategy + frozen
    order) -> v3 (Observer + State transitions + Discount strategy + shipping
    and tax). Added concurrency note and exercises.
- Verified with `uv run jupyter nbconvert --execute` for both notebooks.
