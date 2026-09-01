# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (review pass)
- NB1: added a back-of-the-envelope capacity cell (`size_dlm`) showing that renew
  traffic dominates acquire traffic, that state is trivial, and that a single Raft
  cluster is a hard write ceiling; added the TTL safety-vs-cost trade-off table.
- NB1: the lost-update demo now runs 3 trials and asserts every one loses updates,
  so the teaching point can never silently fail to reproduce.
- NB3: added a demo of `release` with **no owner check** — a stranger deletes the lock
  and two clients end up believing they hold it.
- NB3: added a demo of the **non-atomic check-then-delete** race (GET, pause past TTL,
  DEL) destroying the next owner's lock, next to an atomic compare-and-delete that
  refuses. This is the bug the Redis Lua release script exists to prevent.
- NB3: made the heartbeat demo non-flaky (renew at 1/5 of TTL instead of 1/3, on a
  cadence independent of the poller) and added an assertion plus the cost trade-off.

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
