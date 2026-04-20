# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Reddit` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-20
- Rewrote all three notebooks to match repo conventions (beginner-friendly,
  minimal deps, bad → better → best progression):
  - **01** — added learning objectives, a runnable back-of-envelope calculator, and a
    simulation contrasting compute-on-read vs precomputed Hot feeds.
  - **02** — full runnable SQLite schema, idempotent vote toggling with delta-updates,
    denormalised-vs-live-aggregate timing, materialized-path comment tree, and Pydantic
    request/response models.
  - **03** — three bad→better→best deep-dives: Hot ranking (raw votes → Hacker-News decay →
    Reddit `log + post_time/45000` formula, fixed to use post-time-since-epoch), vote
    counter contention (single row → sharded counters → Redis write-behind), and comment
    trees (N+1 walk → materialized path → closure table with depth filters).
