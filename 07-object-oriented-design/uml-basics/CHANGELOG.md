# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Expanded `01_diagrams.ipynb` with use case diagrams, state diagrams, and a
  stereotype/visibility cheat-sheet.
- Expanded `02_uml_to_python.ipynb` with composition-vs-aggregation code and a
  worked Loan association (reference solution + sequence diagram).
- Added `03_bad_to_best.ipynb` — drives a Checkout refactor (God class → SRP split →
  ports & adapters) using UML to spot the design smells.
- Verified all three notebooks execute end-to-end via `uv run jupyter nbconvert --execute`.

## 2026-04-18
- Scaffolded `Uml Basics` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-08-20
- QA pass: every notebook re-executed end to end and verified clean.
- Redrew three ASCII diagrams whose box borders and arrows had drifted out of
  alignment and become unreadable: the use case diagram in `01_diagrams.ipynb`
  and the stage-2 / stage-3 diagrams in `03_bad_to_best.ipynb`. The use case
  diagram now also gets `«include»` / `«extend»` arrow directions right, with a
  table and a mnemonic for the direction people usually reverse.
- Added a Mermaid appendix to `01_diagrams.ipynb` (class, sequence and state
  diagrams) so the same models can be pasted into a README or PR that renders.
  Kept the notebook markdown-only on purpose — it teaches by diagram and prose.
- `03_bad_to_best.ipynb`: added the `SqlRepo` production adapter the stage-3
  diagram referred to but the code never defined, and extended the test cell to
  check that every adapter really implements its port, that the ports are truly
  abstract, and that prod and test adapters are substitutable.
- `02_uml_to_python.ipynb`: added a verification cell that proves composition
  and aggregation actually differ (a composed `Room` is collected with its
  `House`; an aggregated `Player` outlives a deleted `Team`).
- Notebook hygiene: kernelspec normalised to `Python 3 (.venv)`, saved outputs stripped.
