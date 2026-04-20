# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Linkedin Connections` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18 (notebooks added)
- Added `pyproject.toml` (Python 3.10+, pydantic).
- Added 3 runnable notebooks:
  - `notebooks/01_requirements_and_architecture.ipynb`
  - `notebooks/02_data_and_api.ipynb`
  - `notebooks/03_deep_dive.ipynb`
- Updated `README.md` with setup + notebook links.

## 2026-04-20 (notebooks overhauled)
- Rewrote all three notebooks with explicit **bad → better → best** progressions and more runnable code (~4× more content):
  - **Nb 1**: added runnable back-of-envelope capacity math; fleshed-out architecture diagram with the "why" for each box; added three working edge-storage examples in SQLite (JSON blob → single-row edge table → symmetric adjacency).
  - **Nb 2**: proper pydantic v2 models with validators; a `ConnectionsService` that encodes the full request state machine (send/accept/reject/withdraw) plus runnable invariant tests; HTTP API sketch with notes on pagination, idempotency, and POST vs GET; SQLite-backed symmetric-edges persistence example.
  - **Nb 3**: one-sided BFS vs **bidirectional BFS** benchmarked on a generated 5,000-node preferential-attachment graph; naive PYMK vs **Adamic–Adar** weighting; offline precompute + KV serve demo; dedicated section on the **celebrity / hot-user** problem with three mitigations.
- All notebooks executed end-to-end with `jupyter nbconvert --execute`; outputs are committed.
