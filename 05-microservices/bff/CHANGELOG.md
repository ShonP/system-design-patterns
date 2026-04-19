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
- QA review round 2:
  - `02_worked_example.ipynb`: added explicit **timeout budget** explainer (`total page budget = call budgets + spare`) to clarify the `timeout=1.0` used in the graceful-degradation example.
  - `03_bff_vs_gateway_and_pitfalls.ipynb`: added pitfall #5 **"Invisible BFFs"** with a runnable correlation-ID / tracing demo, and a new **GraphQL-as-alternative** section contrasting when to pick BFF vs. GraphQL.
  - Normalized notebook cell IDs to silence `MissingIDFieldWarning`.
  - Re-verified all notebooks execute cleanly end-to-end.

## 2026-04-19 (QA round 3)
- `01_introduction.ipynb`: added a runnable **"seeing the leakage concretely"** demo that prints the `security` and `shipping_address` fields leaked by the universal API, so beginners can observe the problem instead of just reading about it.
- `02_worked_example.ipynb`: replaced the stale latency numbers in the side-by-side summary table with a **latency-trend** description (`user + orders + recs` vs `max(user, orders)` vs cache hit). Added a note reminding the reader that absolute ms vary by machine; the **ratio** is what matters.
- `03_bff_vs_gateway_and_pitfalls.ipynb`: added a new section **"Real-world BFF job: token exchange"** with a runnable demo where the web BFF exchanges a session cookie and the mobile BFF exchanges an opaque device token for the same internal JWT — a very common reason companies keep a BFF alongside an API gateway. Renumbered subsequent sections (GraphQL, When not to, Checklist).
- Re-executed all three notebooks end-to-end with only the Python standard library.
