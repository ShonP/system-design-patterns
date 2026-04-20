# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Cricinfo` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-20
- Rewrote `notebooks/01_class_design.ipynb` to follow the repo's bad→best progression:
  added a dict-juggling \"bad\" example, class-responsibility table, and an `Enum` demo.
- Expanded `notebooks/02_implementation.ipynb` with `Role` on `Player`,
  `Innings.overs_played()` grouping, cricket-correct `Match.result()` (by runs /
  by wickets / tied), an over-by-over scorecard renderer, a `Commentary`
  observer, and an assertion-based test suite.
- Updated `README.md` concepts section. Both notebooks verified with
  `uv run jupyter nbconvert --execute`.
