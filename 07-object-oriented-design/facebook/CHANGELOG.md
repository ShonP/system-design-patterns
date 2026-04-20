# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Facebook` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-20
- Rewrote `01_class_design.ipynb` as a runnable **bad → best** progression covering four common mistakes (asymmetric friendship, subclass-per-reaction, list-of-reactions, precomputed feeds) each with executable counter-examples.
- Expanded `02_implementation.ipynb` into an 8-step walkthrough: enums (`ReactionType`, `Privacy`), `User` with blocking + `mutual_friends`, `Post`/`Comment`, a single `can_see` visibility function, `NewsFeed` (fanout-on-read), end-to-end demo with assertions, blocking demo, and a bonus `FanoutNewsFeed` (fanout-on-write).
- Replaced deprecated `datetime.utcnow()` with timezone-aware `datetime.now(timezone.utc)`.
- Verified with `uv run jupyter nbconvert --execute` — both notebooks run clean (no warnings, all assertions pass).
