# Atm

> Part of the `07-object-oriented-design/` series. Includes runnable notebooks and references.

## Overview

OOD of an ATM.

## Concepts covered

- God class -> separated hardware / bank / transaction / controller layers
- **State machine** -- `IDLE -> CARD_INSERTED -> AUTHENTICATED <-> TRANSACTING`, with guards
- **Command pattern** -- `BalanceInquiry` / `Deposit` / `Withdraw` / `Transfer` as classes
- **Dependency injection** -- the ATM receives its dispenser, slot, screen and bank
- Encapsulation: `balance` only moves through `Account.debit` / `deposit` / `withdraw`
- Card + PIN auth with a 3-strikes block rule owned by the `Bank`
- Daily cash limit, empty dispenser, and other error paths, backed by assertions

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
