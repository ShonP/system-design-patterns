# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Oo Analysis And Design` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-20
- Expanded `01_process_and_solid.ipynb`: added a runnable noun/verb extractor demo and
  executable bad→good code cells for every SOLID principle (SRP, OCP, LSP, ISP, DIP).
- Expanded `02_refactor_to_solid.ipynb`: refactor now proceeds step-by-step (SRP → DIP/OCP →
  ISP) and ends with self-checking fake-based unit tests plus exercises.
- Verified both notebooks execute end-to-end with `uv run jupyter nbconvert --execute`.

## 2026-08-20
- QA pass: every notebook re-executed end to end and verified clean.
- Strengthened the LSP "good" example in `01_process_and_solid.ipynb`: the split
  hierarchy now demonstrates *why* it works (a `Penguin` has no `fly` at all, so
  the error moves from runtime to type-check time) instead of only asserting it.
- Added a closing "verify the principles" cell that checks each of the five SOLID
  refactors kept the property it claims.
- Added ISP assertions in `02_refactor_to_solid.ipynb` proving `CashOnlyGateway`
  is deliberately *not* `Refundable` and needs no `NotImplementedError` stubs.
- Notebook hygiene: kernelspec normalised to `Python 3 (.venv)`, saved outputs stripped.
