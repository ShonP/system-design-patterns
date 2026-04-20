# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- **Notebook 1**: Added a polyline-simplification (Douglas–Peucker) section showing
  a ~6–12× storage reduction for GPS traces. Reinforces the earlier
  ~530 TB/year storage estimate with a concrete bad→best compression demo.
- **Notebook 2**: Added a cursor-based pagination demo next to the existing
  `LIMIT/OFFSET` example. Makes the previously mentioned "cursor pagination performs
  better at scale" concrete with runnable code that pages Alice's friends feed.
- **Notebook 3**: Added time-bucketed weekly leaderboards. Shows how to maintain
  per-week and per-month sorted sets with Redis `ZADD lt=True` and automatic
  TTL-based cleanup — no cron job needed.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
