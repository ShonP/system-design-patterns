# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Stack Overflow` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_class_design.ipynb, 02_implementation.ipynb.

## 2026-04-20
- Expanded `01_class_design.ipynb`: clarifying questions, actors/use-cases, entities, UML, SOLID check.
- Rewrote `02_implementation.ipynb` as a Bad → Good → Best progression with a self-check cell.
- Added `03_extensions.ipynb`: tags + search (inverted index), badges via observer pattern, moderation (close/reopen/delete), thread-safe voting (race reproduction + lock fix), and pluggable reputation rules (strategy pattern).
- Verified all notebooks execute cleanly with `uv run jupyter nbconvert --execute`.
- Updated README concept list and notebook index.
