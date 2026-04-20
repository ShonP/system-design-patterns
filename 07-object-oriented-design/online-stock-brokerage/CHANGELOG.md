# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Online Stock Brokerage` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-20
- Expanded `01_class_design.ipynb` with runnable bad→best progression (`if/elif` function vs polymorphic `Order` classes).
- Rewrote `02_implementation.ipynb` with clearer structure, working `cancel()`, and a stop-loss scenario. Replaced deprecated `datetime.utcnow()` with timezone-aware `datetime.now(timezone.utc)`.
- Added `03_patterns_and_matching.ipynb`: price-time priority `OrderBook` using twin heaps, Observer pattern (`QuotePrinter`, `MarkToMarket`), and Decorator pattern (`MaxPositionGuard`, `SufficientCashGuard`).
- Verified every notebook executes end-to-end via `uv run jupyter nbconvert --execute`.
