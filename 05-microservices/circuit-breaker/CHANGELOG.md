# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Circuit Breaker` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_introduction.ipynb, 02_worked_example.ipynb.

## 2026-04-19
- QA pass: rewrote `01_introduction.ipynb` with an explicit bad → naive → classic → windowed+thread-safe progression, plus a settings-tuning table.
- Improved `02_worked_example.ipynb` with per-request latency (p50/p99/max) and a fallback (graceful degradation) example.
- Added `03_real_world_patterns.ipynb` covering retry + breaker ordering, observability metrics, production libraries (pybreaker, Resilience4j, Polly, gobreaker, Istio), and when breakers *don't* help.
- Updated `README.md` to reflect new notebooks and concepts.
