# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Expanded notebooks with runnable code throughout (previously nb1 and nb2 were markdown-only).
- Added back-of-envelope capacity estimate and input-normalization helper in nb1.
- Added runnable FastAPI `/suggest` + `/log` service (exercised via `TestClient`) and Pydantic schemas in nb2.
- Restructured nb3 as a bad → best progression: linear scan → sorted + bisect → trie + precomputed top-K, with an apples-to-apples benchmark.
- Clarified that freshness/decay lives in the aggregator, not per-keystroke mutations of the serving trie.
- Added optional typo-tolerance appendix (edit-distance-1 fallback) in nb3.
- Added nb4 with real-world case studies (Google, YouTube, Amazon, Elasticsearch completion suggester) and a runnable Redis-sorted-set-style autocomplete emulation.
- Added `fastapi` and `httpx` dependencies to `pyproject.toml`.

## 2026-04-18
- Scaffolded `Typeahead Autocomplete` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
