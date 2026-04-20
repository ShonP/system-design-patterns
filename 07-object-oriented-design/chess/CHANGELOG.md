# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Chess` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_class_design.ipynb, 02_implementation.ipynb.

## 2026-04-20
- Rewrote `01_class_design.ipynb` to follow a bad -> best progression: starts from a
  monolithic `BadChess` class with `if/elif` on piece types, critiques it, then refactors
  to an abstract `Piece` hierarchy (Strategy pattern). Adds a restaurant analogy, a UML
  sketch, a responsibilities exercise, and SOLID references.
- Rewrote `02_implementation.ipynb` to add Bishop and Queen (with a shared `slide` helper),
  a proper `Board` class with pretty printing, a `Move` dataclass, a `Game` class with
  move history and **undo**, basic **check detection** (plus a "would leave my king in
  check?" guard), explicit illegal-move error messages, and a standalone `in_check` demo.
- Both notebooks now execute end-to-end with `uv run jupyter nbconvert --execute`.
