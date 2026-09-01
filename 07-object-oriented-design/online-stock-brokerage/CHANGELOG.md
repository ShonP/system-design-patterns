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

## 2026-08-20
- QA pass: every notebook re-executed end to end and verified clean.
- Fixed `Exchange.tick()` in `02_implementation.ipynb`: it updated `stock.price`
  as a side effect of iterating resting orders, so a price move on a symbol with
  an empty book was silently lost (the stop-loss scenario had to poke
  `aapl.price` directly to work around it). The exchange now owns its market data
  via `list_stock()` / `stocks`, and `tick()` updates the price before matching.
- Added "verify the design" assertion cells to all three notebooks: order-type
  polymorphism and the `qty > 0` invariant (01), cash/share conservation, resting
  limits and cancel semantics (02), and price-time priority, observer fan-out and
  decorator stacking (03).
- `PricingStrategy`-style contracts are now checked, not just described.
- Notebook hygiene: kernelspec normalised to `Python 3 (.venv)`, saved outputs stripped.
