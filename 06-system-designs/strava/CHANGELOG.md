# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-21
Content-correctness review. Several things the lab *claimed* disagreed with what its
own code printed; the seed data disagreed with itself. Fixed at the root, and every
lesson now carries an assertion so it fails loudly if it stops reproducing.

- **Seed data (`db/init.sql`)**: activity 1 stored 2540 m and 780 s for a track whose
  ten GPS points sum to 909.5 m (activity 2: 8500 m stored, 2828 m traced). Both
  summaries now match their tracks, the Embarcadero Sprint's length matches the stretch
  its endpoints describe, and the two seeded efforts equal what notebook 3 recomputes.
  Activity-1 breadcrumbs are now 30 s apart, which is what notebook 1 says they are.
  Bulk activities drew `completed_at` independently of `started_at`, so some finished
  before they began — it is now derived from the end time minus the duration.
  ⚠️ These only load into a fresh volume: `docker compose down -v && docker compose up -d`.
- **Notebook 1**: added an *Elevation Gain* section — summing raw altitude deltas turns
  ±3 m of GPS noise into 1091 m of climbing on a 120 m hill; smoothing plus a hysteresis
  threshold recovers 116 m, and a window-size sweep shows where smoothing starts eating
  the summit. Douglas–Peucker measured `epsilon` in raw degrees, so the tolerance
  silently changed with latitude (1° of longitude is 88 km in SF, 111 km for latitude);
  it now projects to metres. Its demo trace was 150 points with two supposedly-real
  turns that were actually collinear, and printed a 50× compression ratio directly above
  prose claiming 6–12×; it is now a realistic 600-point jittered track that reports
  11.5×, a bounded 10 m error, and the fact that simplification makes the *distance*
  more accurate. The "~450 TB/year" figure now comes from the notebook's own estimate.
- **Notebook 2**: cursor pagination used a bare `completed_at`, which skips every row
  tied on it — the cell now seeds a tie, shows the naive cursor losing rows, and fixes
  it with a `(completed_at, id)` keyset cursor. The feed cache key omitted `page_size`,
  so a request for 3 rows was served a cached 10-row payload. The live-tracking demo
  read and wrote in lockstep while the prose described a 7 s offset poll; it now runs
  two independent clocks against Redis and measures staleness and redundant polls.
- **Notebook 3**: the matcher took the *first* point within 100 m of an endpoint rather
  than the nearest, which under-measured efforts and disagreed with the PostGIS cell;
  that cell's `start_matches JOIN end_matches` was a cross join reporting four
  contradictory times for one effort, now `DISTINCT ON`. Added a *Bad → Best* section:
  endpoint-only matching credits a 2.6×-length detour with a segment time, and a
  path-length ratio check rejects it while still accepting a noisy honest effort.
  `record_segment_effort` claimed to "update both Postgres and Redis" but wrote only
  Redis, so the next rebuild-from-Postgres erased the effort; same for the `ZINCRBY`
  demo. Both now write through, and use `ZADD ... lt=True` instead of a read-then-write
  race. Weekly buckets are keyed off the effort's own timestamp rather than the local
  clock, which could land in a different ISO week than UTC Postgres.
- **Assertions added throughout** (~35), including: stored distance vs recomputed track,
  PostGIS vs Python haversine, device vs server distance after batch upload, the fake
  mountain actually appearing and the fix landing within 10% of truth, summit
  preservation under smoothing, Douglas–Peucker's error bound, the naive cursor
  actually losing rows, cache invalidation leaving no survivors, Redis leaderboards
  matching a Postgres rebuild, and Redis vs SQL agreeing on who is winning.
- **RNGs seeded** in every simulation (notebooks 1, 2 and 3) — the printed numbers are
  now reproducible.
- **README / notebook summaries**: added explicit "what this toy does *not* do" sections
  (no map matching, no polyline segments, no cheat detection, row-per-GPS-sample
  storage, benchmarks that measure shape rather than scale).

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
