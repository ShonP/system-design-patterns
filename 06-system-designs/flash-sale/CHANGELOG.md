# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

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
