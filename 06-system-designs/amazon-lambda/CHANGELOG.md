# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Amazon Lambda` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18 (notebooks added)
- Added `pyproject.toml` (Python 3.10+, pydantic).
- Added 3 runnable notebooks:
  - `notebooks/01_requirements_and_architecture.ipynb`
  - `notebooks/02_data_and_api.ipynb`
  - `notebooks/03_deep_dive.ipynb`
- Updated `README.md` with setup + notebook links.

## 2026-04-19 (notebooks rewritten: bad → best progression)
- Rewrote all three notebooks to follow the repo's bad → best progression.
- Notebook 1: added runnable back-of-envelope calculator, control plane vs data plane ASCII diagram, and preview of the 4 core flows.
- Notebook 2: added naive dict store (❌) → pydantic validation (⚠️) → versioned store with alias-based deploys + TTL metadata cache (✅). Includes a tiny `FakeS3` for content-addressable code storage.
- Notebook 3: added runnable simulations for cold vs warm start, TTL warm pool, per-account + per-function concurrency limits with 429 throttling, async queue with exponential backoff + DLQ, power-of-two-choices scheduling, and SnapStart-style snapshot restore.
- All notebooks executed end-to-end with `jupyter nbconvert --execute` — no cell errors.
