# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.

## 2026-08-21 (correctness audit)

Content review of all six notebooks. Every claim of a speedup, a hit rate or a
capacity multiplier is now computed and asserted, so the lab fails loudly if it
stops reproducing its own lesson instead of quietly teaching nothing.

**Notebook 1 — the problem**
- `measure_query` was annotated `-> float` but returned a tuple.
- The load test measured a connection handshake per request without saying so.
  It now breaks the latency down into handshake vs query, points at the two
  different fixes in Notebook 2, and asserts that latency really does climb with
  concurrency.

**Notebook 2 — database optimization**
- The before/after index comparison printed "Expect Seq Scan" / "Notice Index
  Scan" without checking either. Both plans are now asserted, and timings are
  best-of-3 instead of a single noisy sample.
- The covering-index cell claimed "Index Only Scan — that means zero table
  reads", but without a `VACUUM` the visibility map is stale and the scan does
  heap fetches anyway. It now runs `VACUUM ANALYZE users` first and asserts
  `Heap Fetches: 0`.
- **The BRIN demo rested on a false premise.** Its comment said "rows were
  inserted roughly in time order", but `init.sql` generates `posts.created_at`
  as `NOW() - random() * 30 days` — the column is randomly ordered, so BRIN
  pruned nothing. Rewritten to measure `pg_stats.correlation` and compare
  discarded rows on a scattered copy vs a physically sorted copy, forcing a
  BRIN-only plan on both. The counter-example is now the lesson.
- The BRIN/B-tree size comparison compared `pg_size_pretty` strings; it now
  compares bytes and asserts the ratio.
- The column-order cell hard-coded "Falls back to Seq Scan"; it now reports the
  plan it actually got.
- **Added pool sizing arithmetic** (the section previously had none): Little's
  Law for the in-flight connection count, the fan-in multiplication across app
  servers against `max_connections`, why a bigger pool is usually slower, and
  what PgBouncer transaction mode costs you.

**Notebook 3 — denormalization**
- Added a demo that makes denormalized copies **drift**: rename a user, watch
  the JOIN and the `feed_items` copy disagree, then pay the fan-out to fix it.
  Cell 10 claimed "data can become inconsistent" but never showed it.
- Added a demo that watches a materialized view **go stale**: insert one review,
  see the live aggregate move and the view not, then `REFRESH`. The quiz already
  asserted this happens.
- The materialized-view speedup was a single unverified sample; now best-of-3
  with an assertion, plus a note that `REFRESH` (non-`CONCURRENTLY`) takes an
  ACCESS EXCLUSIVE lock.
- Made the normalized-vs-denormalized comparison honest: at `LIMIT 20` with an
  index the join is already cheap, and the notebook now says so.

**Notebook 4 — read replicas**
- The stale read *was* reproduced but nothing asserted it. Added assertions that
  reads inside the lag window really miss, that the replica really serves the
  previous value while the leader has the new one, and that the writer is routed
  to the leader while a non-writer is not.
- Made the read-your-own-writes sticky window an explicit `sticky_window_ms`
  knob and **added a cell where it is too short**, so the guarantee visibly
  breaks. Points at `pg_stat_replication.replay_lag` and at LSN-based reads as
  the version with no magic number.
- Said out loud that a non-writer still reads stale data — that is the trade.
- **Rewrote the scaling cell.** It previously printed
  `capacity = num_replicas * 10000` (a hard-coded claim) and measured latency of
  sequential reads with no queueing, so replica count changed nothing. It now
  runs a seeded queueing simulation, binary-searches the highest offered load
  that still meets a p99 SLO, reports the measured multiplier (~7.5x at 8
  replicas with random routing, ~9.7x with least-busy), shows one replica
  drowning at a fixed 1,200 rps, and asserts all of it. Adds the honest notes:
  p50 does not improve, writes do not scale, WAL replay competes with reads.

**Notebook 5 — application caching**
- **"WRITE-BEHIND (INVALIDATE)" was a mislabelled pattern.** Deleting the cache
  entry on write is write-*invalidate*; write-behind means writing to the cache
  and flushing to the DB asynchronously. Both are now listed correctly, and the
  quiz question that repeated the error was replaced.
- **Added the invalidation race**, which the lab had no coverage of: three
  hand-stepped interleavings showing that delete-before-commit leaves a
  permanently stale entry, that commit-then-delete is correct, and that
  commit-then-delete *still* loses to a reader that was already mid-read — which
  is why the TTL is not optional.
- `update_user` already had the ordering right; it now says why, at the line.
- "Second read was MUCH faster" is now asserted, as are the negative-cache hit
  counts and the warm-cache hit rate.
- The hit-rate simulation used an unseeded RNG and a cache that might already be
  warm. Seeded, cleared first, and it now asserts the real invariant
  (`misses == distinct keys touched`).
- Replaced the claim that the 90% hit rate comes from traffic skew — it does
  not, at 100 keys uniform traffic gives ~90% too. The cell now computes hit
  rates across four key-space/skew combinations to show where skew actually
  matters.

**Notebook 6 — advanced cache patterns**
- **The distributed lock released locks it no longer owned.** It stored `"1"` and
  deleted unconditionally in `finally`, so a DB call that overran the 10s lock
  TTL would delete the *next* holder's lock. Now uses a per-caller token and an
  atomic compare-and-delete Lua script.
- **`SingleFlightCache` deadlocked every waiter if the loader raised** — the
  shared `Future` was never completed. Added `set_exception`, plus a demo with
  20 threads on a failing loader that asserts nobody hangs.
- **Hot-key fanout silently broke reads during the cold→hot transition.** Once a
  key crossed the threshold, `get` read shard keys that no `set` had written
  yet and returned `None`. Added a fallback to the base key with a shard
  back-fill, and an assertion that all 150 reads return data.
- **Prose and code disagreed about the refresh probability**: the text said "at
  10 seconds remaining: 20% chance", the formula gives 8.3%. The text now states
  the formula and its real values.
- **The early-refresh demo was sequential**, and a sequential loop cannot produce
  a stampede. Added a seeded simulation that replays one arrival stream through
  both strategies and measures *peak concurrent* DB queries (60 vs 3), sweeps
  BETA at two request rates, and shows the honest cost: at light traffic eager
  refreshing does more total work than the naive cache. Notes that this linear
  ramp is rate-blind and points at XFetch.
- Cache versioning kept versions in a process-local dict, which defeats the
  point across app servers. Added a shared Redis-counter variant, and spelled
  out that a cache fill must reuse the version captured when the read started.
- Added assertions to the stampede reproduction, the lock, and single-flight.
