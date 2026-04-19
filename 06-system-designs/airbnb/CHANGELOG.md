# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Airbnb` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18 (notebooks added)
- Added `pyproject.toml` (Python 3.10+, pydantic).
- Added 3 runnable notebooks:
  - `notebooks/01_requirements_and_architecture.ipynb`
  - `notebooks/02_data_and_api.ipynb`
  - `notebooks/03_deep_dive.ipynb`
- Updated `README.md` with setup + notebook links.

## 2026-04-19 (expanded content)
- Rewrote all 3 notebooks with beginner-friendly explanations and clear
  **bad → better → best** progressions:
  - `01` — added runnable capacity math (QPS, storage, availability rows),
    booking sequence diagram, clearer service rationale.
  - `02` — added SQLite availability-table demo (DB-enforced uniqueness vs.
    naive in-memory range scan), richer Pydantic models with validators,
    idempotency-key demo.
  - `03` — added four deep dives with runnable code: double-booking race
    (no-lock → mutex → DB unique constraint), geo search (linear scan →
    grid index → S2/H3 discussion), cache-aside with single-flight anti-
    stampede, token-bucket rate limiter. Plus a "real-world echoes"
    section and exploration ideas.
- All cells execute cleanly under `uv run jupyter nbconvert --execute`.
