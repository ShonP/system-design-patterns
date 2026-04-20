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
