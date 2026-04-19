# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Rewrote all three notebooks with runnable code and bad→best progression.
- NB1: added race-condition demo (with/without lock) motivating distributed locks,
  plus architecture picking-rubric and real-world backends table.
- NB2: added Pydantic v2 request/response models, bad→better→best API evolution,
  and an in-memory `InMemoryLockService` demo showing owner+token checks on release.
- NB3: extended toy `LockManager` with a full end-to-end GC-pause simulation
  contrasting an `UncheckedResource` (corruption) vs a `FencedResource` (safe),
  added a heartbeat/renewal demo, and a real-world examples / ship-checklist section.

- Scaffolded `Distributed Lock Manager` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
