# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (review pass)
- NB1: fixed `redis_shards` to use ceiling division (it previously reported 7 shards
  for a load needing 6, and 2 for a load needing 1); added peak-bandwidth and hot-state
  estimates; removed a stray value echoed by the last cell; reconciled the commentary
  with the computed 600k RPS (it previously said "1M RPS").
- NB3: V1 now runs 5 trials and asserts overselling on every one, instead of printing
  "oversold by X (or undersold by Y)" and hoping the race showed up.
- NB3: replaced the shared `reserved[0] += 1` tally used by all versions with per-thread
  counters. The old tally was itself an unsynchronised read-modify-write, so the
  `assert sold == INITIAL` guarding V2/V3 was a latent flake.
- NB3: V2 and V3 now repeat the same concurrent load 3x, so "no overselling" is shown
  to be stable rather than a single lucky run.
- NB3: added a measured trade-off for hot-key sharding — with demand close to supply,
  64 shards strand 4% of inventory and produce 242 false "sold out" responses.
- NB3: rewrote the admission-queue commentary; the `capacity=500` row leaves half the
  inventory unsold, which the old text did not mention.

## 2026-04-18
- Scaffolded `Flash Sale` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-20
- Expanded all three notebooks with runnable examples and a bad → best progression.
- Notebook 1: added back-of-the-envelope capacity planning code and real-world scale examples
  (Alibaba 11/11, Ticketmaster × Taylor Swift, Xiaomi, Supreme).
- Notebook 2: added pydantic request/response models with validation, a Redis key design
  table (including hot-key sharding), and an idempotency-key demo.
- Notebook 3: restructured as V1 naive (oversells) → V2 locked → V3 sharded atomic CAS →
  V4 full path with rate limiter, bounded admission queue, reservation TTL, and reaper.
- Verified every code cell executes without errors.
