# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Library Management` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_class_design.ipynb, 02_implementation.ipynb.

## 2026-04-20
- Rewrote both notebooks for depth and runnability:
  - `01_class_design.ipynb`: bad god-class → separated classes → SRP + Strategy + Observer design, with UML-style text diagram.
  - `02_implementation.ipynb`: full system with `Catalog` search, reservation queue (FIFO), pluggable `FineCalculator` (incl. student-discount variant), `Notifier` (observer), overdue sweep, and edge-case assertions.
- Verified end-to-end with `uv run jupyter nbconvert --execute`.

## 2026-08-20
- QA pass: re-verified every notebook executes end to end with
  `uv run jupyter nbconvert --execute`; normalized the kernelspec to
  `Python 3 (.venv)` and stripped saved outputs.
- The lab named **Observer** but shipped a single injected `Notifier` (a Strategy shape).
  `Library` now owns a real subscriber list — `subscribe` / `unsubscribe` / `_publish` — with
  two concrete observers (`PrintObserver`, `AuditLog`) firing on one event, plus a table in
  notebook 1 explaining how Strategy and Observer actually differ.
- Fixed an aliasing bug in the demos: one `Member` object was registered into three
  `Library` instances, so `active_loans` accumulated across them (and would silently break
  `MAX_LOANS`). Each library now gets its own `Member`, with a note on why.
- Added the missing proofs for rules the notebook already claimed: the `MAX_LOANS` limit,
  FIFO reservation queue-jumping, observer fan-out/detach.
- Named the reservation-starvation hole (a notified reserver who never returns blocks the
  copy forever) instead of leaving it silent.
