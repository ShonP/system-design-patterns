# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Collaborative Whiteboard` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18 (notebooks added)
- Added `pyproject.toml` (Python 3.10+, pydantic).
- Added 3 runnable notebooks:
  - `notebooks/01_requirements_and_architecture.ipynb`
  - `notebooks/02_data_and_api.ipynb`
  - `notebooks/03_deep_dive.ipynb`
- Updated `README.md` with setup + notebook links.

## 2026-04-19 (review + expansion)
- Expanded all three notebooks with beginner-friendly explanations and real-world references (Figma, Miro, Excalidraw, tldraw, Yjs, Automerge).
- Notebook 1: added explicit **bad → better → best** architecture progression and a back-of-envelope table.
- Notebook 2: added pydantic `ValidationError` demos (bad op kind, negative lamport, delete without shape_id via `model_validator`), a **bad vs good API** table, and expanded WebSocket message schema.
- Notebook 3: added a **naive-divergence demo** contrasting with the LWW CRDT, an **offline-merge demo** (partitioned edits converge), a toy **pub/sub + WS gateway** simulation, a **snapshot + op log** example, a **presence TTL** example, and a CRDT-vs-OT note.
- Verified every notebook runs end-to-end with `jupyter nbconvert --execute`.
