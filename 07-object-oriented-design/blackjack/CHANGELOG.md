# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Rewrote `01_class_design.ipynb` with an explicit **bad → best** progression: a procedural one-function Blackjack with call-outs for code smells, then the clean OO decomposition with runnable skeletons.
- Rewrote `02_implementation.ipynb` to build the game class-by-class with small verifying runs (Card value checks, Deck sanity, Hand `assert`-based unit tests, a full round, then multi-seed replay). Fixed the dead-code `hasattr(..., "is_bust")` loop and added `is_blackjack()` on `Hand`.
- Added `03_extensions.ipynb`: Strategy Pattern (`HitStrategy` / `HitUntil` / `NeverHit` / `AggressiveThenFold`), `Chips` class with blackjack 3:2 payout, a `Table` wiring it together, and a discussion of splits framed as the Open/Closed Principle.
- Verified all three notebooks execute cleanly via `uv run jupyter nbconvert --execute`.
- Updated README concepts list and notebook index.

## 2026-04-18
- Scaffolded `Blackjack` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
