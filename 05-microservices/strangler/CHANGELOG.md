# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Strangler` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_introduction.ipynb, 02_worked_example.ipynb.

## 2026-04-19
- Greatly expanded all notebooks with a clear bad-practice → best-practice progression.
- `01_introduction.ipynb`: added big-bang-rewrite failure mode, tree metaphor, how to pick the first slice, four migration phases, common pitfalls, real-world stories (Amazon, eBay, Shopify, GitHub, Netflix, Stack Overflow).
- `02_worked_example.ipynb`: added dark launch / shadow traffic with mismatch detection, kill-switch / instant rollback, production checklist before ramping.
- Added `03_end_to_end_banking.ipynb`: full 5-phase migration of a banking monolith with dual-write data migration, per-op metrics, latency tracking, retirement. Also covers event interception, branch-by-abstraction, CDC, and UI-layer strangling.
- Verified all notebooks execute end-to-end with no errors.
