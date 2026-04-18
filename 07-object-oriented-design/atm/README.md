# Atm

> Part of the `07-object-oriented-design/` series. Includes runnable notebooks and references.

## Overview

OOD of an ATM.

## Concepts covered

- States and transitions
- Card, PIN, transactions
- Hardware abstractions

## Setup

```bash
cd 07-object-oriented-design/atm
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_class_design.ipynb`](./notebooks/01_class_design.ipynb) -- ATM, Account, Card, Transaction
- [`notebooks/02_implementation.ipynb`](./notebooks/02_implementation.ipynb) -- Withdraw / deposit / balance with a state machine

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
