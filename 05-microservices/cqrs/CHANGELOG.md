# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Cqrs` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_introduction.ipynb, 02_event_sourced_example.ipynb.

## 2026-04-19
- Reworked lab for clearer bad → best progression and beginner-friendly explanations.
- Notebook 01: added shared-model "pain" demo with a 200k-order benchmark, then projection, then incremental sync.
- Notebook 02: rewrote event-sourcing walk-through; added cancellation handling, multi-projection ordering, replay-to-add-new-view demo, and snapshotting.
- Added Notebook 03: when to use CQRS, eventual-consistency simulation with a background projector, and a store + analytics worked example.
- README updated with the new notebook list.

## 2026-04-19 (review pass)
- Notebook 02: made projections independent — removed cross-projection state
  sharing (`p_top` no longer reads `p_summary`'s `active_orders`); each projection
  now owns its own `_orders` map, which is the real-world rule.
- Notebook 02: snapshot demo now actually **replays newer events** after restore,
  showing the full "load snapshot + catch up" lifecycle.
- Notebook 02: added an "outbox pattern" explainer — how production systems
  atomically commit business state + event publication.
- Notebook 03: added a runnable **read-your-writes** demo using a monotonic
  version counter and a `Condition` variable so the query waits for the
  projection to catch up.
