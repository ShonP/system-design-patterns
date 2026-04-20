# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `S3` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18 (notebooks added)
- Added `pyproject.toml` (Python 3.10+, pydantic).
- Added 3 runnable notebooks:
  - `notebooks/01_requirements_and_architecture.ipynb`
  - `notebooks/02_data_and_api.ipynb`
  - `notebooks/03_deep_dive.ipynb`
- Updated `README.md` with setup + notebook links.

## 2026-04-20 (review & expansion)
- Expanded all three notebooks from ~70-line stubs to beginner-friendly,
  runnable lessons that follow the repo's **bad → best** progression.
- Notebook 1: added back-of-envelope math, replication vs erasure-coding
  cost comparison, and a durability probability model (why "11 nines"?).
- Notebook 2: progressive toy S3 — naive dict → versioned store with
  tombstones + ETag → multipart upload (with an S3-style composite ETag).
  Added a section on consistency tradeoffs.
- Notebook 3: added consistent-hashing placement demo (modulo vs ring) and
  a lifecycle-policy engine; kept presigned URLs + XOR erasure coding.
- All notebooks executed end-to-end with `jupyter nbconvert --execute`.
