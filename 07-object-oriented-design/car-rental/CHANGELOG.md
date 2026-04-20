# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Car Rental` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-20
- Expanded `01_class_design.ipynb`: beginner-friendly problem framing, actors & use cases, class-responsibility table, design decisions with rationale, patterns callout, and trade-offs section.
- Rewrote `02_implementation.ipynb` as a **bad → better → best** progression:
  - v0 God class with `is_available` boolean and `if/elif` pricing (and what breaks).
  - v1 polymorphic `Vehicle` hierarchy (Open/Closed) — still naive availability.
  - v2 final design: `ReservationState` state machine with guarded transitions, overlapping-date availability, `PricingPolicy` Strategy (flat vs. weekend+weekly), `Payment` lifecycle, multi-branch `Branch` with category-filtered search, and late-return fees.
- End-to-end demo covers search, booking, collision, cancellation+refund, late return, and weekly discount.
- Verified with `uv run jupyter nbconvert --execute`.
