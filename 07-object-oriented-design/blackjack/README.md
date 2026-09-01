# Blackjack

> Part of the `07-object-oriented-design/` series. Includes runnable notebooks and references.

## Overview

Object-oriented design of the classic card game, with correct Ace handling and a simple dealer.

## Concepts covered

- Bad (one-function) design → clean OO design (bad→best progression)
- `Card`, `Deck`, `Hand` classes with clear single responsibilities
- Polymorphic `Player` vs `Dealer` decision-making
- Soft-vs-hard Ace rule encapsulated in `Hand.value()`
- Game loop and settlement
- **Strategy Pattern** — swap playing styles without subclassing
- **Composition over inheritance** — `Player` *has a* `Strategy` and `Chips`
- Betting with a `Chips` class, blackjack 3:2 payout, pushes
- Stateless strategies: why a shared strategy object must not remember rounds
- Pure settlement rule (`outcome()`) separated from printing, so every branch is testable
- Discussion of splits / Open-Closed Principle for future extensions

## Setup

```bash
cd 07-object-oriented-design/blackjack
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_class_design.ipynb`](./notebooks/01_class_design.ipynb) — Bad design → clean OO design, domain model, class relationships
- [`notebooks/02_implementation.ipynb`](./notebooks/02_implementation.ipynb) — Working Python implementation, built class by class, with inline assertions
- [`notebooks/03_extensions.ipynb`](./notebooks/03_extensions.ipynb) — Strategy Pattern, betting with `Chips`, and a discussion of splits (Open/Closed)

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
