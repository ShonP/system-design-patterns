# Chess

> Part of the `07-object-oriented-design/` series. Includes runnable notebooks and references.

## Overview

OOD of a chess game.

## Concepts covered

- God class with string piece types -> "Replace Conditional with Polymorphism"
- When subtype polymorphism is right and when **Strategy** would be (they are not the same)
- All six pieces owning their own movement rules, sharing a `slide` helper
- `Board` as a thin container; dependency direction `Game -> Board -> Piece`
- `Move` as a data object, which makes undo and history trivial
- Check detection by reusing `valid_moves`; geometry vs legality (self-check, pins)

## Setup

```bash
cd 07-object-oriented-design/chess
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_class_design.ipynb`](./notebooks/01_class_design.ipynb) -- Board, Piece hierarchy, Move
- [`notebooks/02_implementation.ipynb`](./notebooks/02_implementation.ipynb) -- All six pieces, `Board`, `Move`/undo, turn order, check detection, and a "verify the design" assertion cell

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
