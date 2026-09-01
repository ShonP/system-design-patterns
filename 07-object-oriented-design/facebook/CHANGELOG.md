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

## 2026-08-20
- QA pass: re-verified every notebook executes end to end with
  `uv run jupyter nbconvert --execute`; normalized the kernelspec to
  `Python 3 (.venv)` and stripped saved outputs.
- Corrected the explanation of why `User` defines `__hash__`/`__eq__` by hand
  (`@dataclass` sets `__hash__ = None` whenever it generates `__eq__` — the old comment
  blamed "mutable fields", which is not the rule).
- Documented why `add_friend` fails *silently* on a blocked pair (leaking the block would
  be a privacy bug) and contrasted it with the fail-loud default.
- Added a "verify the design" cell asserting friendship symmetry/idempotence, block
  precedence over PUBLIC, one-reaction-per-user, the full `can_see` truth table, and
  feed ordering/limit.
