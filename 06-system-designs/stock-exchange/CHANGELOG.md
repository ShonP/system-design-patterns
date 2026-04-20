# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Stock Exchange` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18 (notebooks added)
- Added `pyproject.toml` (Python 3.10+, pydantic).
- Added 3 runnable notebooks:
  - `notebooks/01_requirements_and_architecture.ipynb`
  - `notebooks/02_data_and_api.ipynb`
  - `notebooks/03_deep_dive.ipynb`
- Updated `README.md` with setup + notebook links.

## 2026-04-20 (expanded + bad→best progression)
- Rewrote all 3 notebooks with clear bad→best progressions and runnable examples.
- **NB1**: added back-of-envelope sizing cell, a runnable non-determinism demo
  (multi-threaded vs single-threaded matcher), and a real-world comparison
  table (Nasdaq INET, NYSE Pillar, LMAX Disruptor, CME).
- **NB2**: added `float` vs integer-ticks demo, pydantic validation with
  rejected inputs, `client_order_id` idempotency demo, JSON wire round-trip,
  and models for `market`/`IOC`/`FOK` order types.
- **NB3**: replaced minimal matcher with a full `MatchingEngine` (cancel,
  partial fills, top-of-book), benchmarked it against the naive version
  (~1000× faster), added a WAL-replay determinism demo, and a timed
  fan-out comparison showing why market data must leave the hot path.
- Verified: all three notebooks execute end-to-end via `jupyter nbconvert --execute`.

