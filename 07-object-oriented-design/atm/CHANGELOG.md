# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Atm` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_class_design.ipynb, 02_implementation.ipynb.

## 2026-04-20
- Expanded both notebooks into a full bad→best progression.
- `01_class_design.ipynb`: added a runnable "God class" anti-pattern, a responsibility-split table, ASCII class diagram, session state machine, and a tiny skeleton demo.
- `02_implementation.ipynb`: full working ATM with checking/savings accounts, Command-pattern `Transaction` hierarchy (`BalanceInquiry`, `Deposit`, `Withdraw`, `Transfer`), 3-strikes-PIN blocking, daily withdrawal limit, cash-dispenser exhaustion, receipt printing, and happy-path + error-path demos.
- Verified with `uv run jupyter nbconvert --execute` (0 errors).
