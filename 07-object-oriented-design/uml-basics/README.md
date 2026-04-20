# UML Basics

> Part of the `07-object-oriented-design/` series. Includes runnable notebooks and references.

## Overview

A gentle introduction to the three UML diagrams you'll actually use: class, sequence, activity.

## Concepts covered

- Class diagram notation (fields, methods, visibility, stereotypes)
- Relationships: inheritance, composition, aggregation, association, dependency
- Sequence diagrams for call flow
- Activity diagrams for process flow
- Use case diagrams (actors, `<<include>>`, `<<extend>>`)
- State diagrams for object lifecycles
- Mapping UML to Python code (ABCs, dataclasses, composition vs aggregation)
- Using UML to drive a **bad → better → best** refactor

## Setup

```bash
cd 07-object-oriented-design/uml-basics
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_diagrams.ipynb`](./notebooks/01_diagrams.ipynb) — Class, sequence, activity, **use case**, and state diagrams with ASCII examples, plus a visibility/stereotype cheat-sheet
- [`notebooks/02_uml_to_python.ipynb`](./notebooks/02_uml_to_python.ipynb) — Turn a UML sketch into runnable Python (Library + Loan), composition vs aggregation in code
- [`notebooks/03_bad_to_best.ipynb`](./notebooks/03_bad_to_best.ipynb) — Drive a refactor with UML: God class → single-responsibility split → ports & adapters

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
