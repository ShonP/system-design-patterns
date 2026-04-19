# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Bff` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_introduction.ipynb, 02_worked_example.ipynb.

## 2026-04-19
- QA review: expanded all notebooks with clearer bad→best progressions, real-world context (Netflix), and more concepts.
- `01_introduction.ipynb`: added client-comparison table, sensitive-field leakage example, three-way BFF comparison (mobile/web/TV), and BFF-vs-Gateway preview table.
- `02_worked_example.ipynb`: added graceful-degradation scenario (fragile vs. resilient BFF), tiny TTL cache demo, and a side-by-side latency/robustness summary.
- Added `03_bff_vs_gateway_and_pitfalls.ipynb`: BFF vs. API Gateway, pitfalls (duplicated business rules, BFFs calling each other, auth sprawl, BFF bloat), when NOT to use a BFF, and a review checklist.
- All notebooks verified to execute end-to-end with only the Python standard library.
