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
