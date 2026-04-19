# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Code Deployment` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-19
- **Major overhaul** of all three notebooks into a bad → better → best progression with runnable examples:
  - `01_requirements_and_architecture.ipynb` now includes a three-step pipeline runner (sequential → topo-sorted with stop-on-failure → parallel DAG execution with `ThreadPoolExecutor`).
  - `02_data_and_api.ipynb` adds Pydantic validators, a tiny in-memory `DeployService` (webhook → artifact → deploy → rollback), and a content-addressed artifact demo that shows why `:latest` is unsafe.
  - `03_deep_dive.ipynb` adds runnable **big-bang**, **rolling**, **blue/green**, and **canary** deploy simulators, plus an SLO-gated auto-rollback with a minimum-sample guard.
- All notebooks executed end-to-end with `jupyter nbconvert --execute` to guarantee they run clean.
- Updated `README.md` concepts list.
