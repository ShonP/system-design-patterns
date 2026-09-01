# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Restaurant` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-20
- Rewrote `01_class_design.ipynb` with bad (god class) → best progression, UML-style diagram, state machines, and SOLID tour.
- Expanded `02_implementation.ipynb`: added `Bill` value object, `Staff` hierarchy (Waiter / Chef / Manager), `Kitchen` FIFO queue, `Reservation`, guardrail demos, and end-to-end dinner scenario. Every cell asserts behaviour.
- Added `03_polymorphism_and_patterns.ipynb` covering **Strategy** (standard / happy-hour / loyalty pricing), **Factory** (menu from JSON config), and **Observer** (kitchen / SMS / manager dashboard pub-sub).
- Verified all notebooks run end-to-end with `uv run jupyter nbconvert --execute`.

## 2026-08-20
- QA pass: every notebook re-executed end to end and verified clean.
- `01_class_design.ipynb`: the god-class critique was a list of claims; it now
  has a runnable cell that *executes* four illegal states (placing an order for
  an unseated table, paying without serving, paying twice, ordering an item that
  isn't on the menu) so the reader watches them go through without error.
- `02_implementation.ipynb`: `expect_error` printed "❌ should have failed" but
  did not raise, so a missing guard would pass silently. It now raises, and the
  guardrail cell covers the full lifecycle plus kitchen/table/reservation rules.
- `03_polymorphism_and_patterns.ipynb`:
  - Fixed `LoyaltyPricing`, which documented a discount "before tax/tip" but
    subtracted from the final total, leaving tax computed on the undiscounted
    subtotal. Discounts now reduce the amount the base strategy prices (via a
    `DiscountedOrder` view), so tax and tip follow — and strategies genuinely
    compose (`Loyalty(HappyHour(Standard))`).
  - `ObservableOrder` used a shared class-level `events` hub, which is a global
    in disguise; the hub is now an injected field, so two hubs stay isolated.
  - Added a "verify the patterns" cell asserting the properties that make
    Strategy, Factory and Observer worth the names.
- Notebook hygiene: kernelspec normalised to `Python 3 (.venv)`, saved outputs stripped.
