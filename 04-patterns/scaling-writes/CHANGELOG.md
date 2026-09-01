# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.

## 2026-04-19
- QA pass: re-ran every notebook end-to-end against the lab's own docker-compose stack.
- Fixed `05_batching_aggregation.ipynb`: setup cell used the wrong database name
  (`writescaling`) and user (`postgres`). Now matches the rest of the lab
  (`writes_demo` / `demo` / `demo`) and uses a `get_connection()` helper.
- Improved the index-overhead benchmark in `02_database_optimization.ipynb`:
  inserts 10,000 rows averaged over 3 trials (up from 1,000 single-shot), adds
  a composite and a GIN-on-JSONB index so the cost of maintaining indexes on
  every INSERT is clearly visible instead of getting lost in timing noise.

### 2026-04-19 (QA review, round 3)
- **`03_sharding.ipynb`**: Added a hands-on **PostgreSQL declarative
  partitioning** section. Previously every sharding demo was in-memory
  Python; this new section creates a `PARTITION BY HASH` table with 4
  child partitions, inserts 10k rows, shows the near-even row count
  per partition (~2,500 each), and uses `EXPLAIN` to demonstrate
  **partition pruning** (a `user_id = 42` query scans only 1 of 4
  partitions). Bridges the gap between the theory and what PostgreSQL
  actually does on disk.
- **`04_queues_load_shedding.ipynb`**: Fixed the bursty-traffic demo so
  it actually triggers load shedding. It used to enqueue 500 writes
  into a 1,000-slot queue (impossible to overflow, `dropped = 0`).
  Now pushes 1,500 writes so the `dropped` counter climbs to 500,
  making the whole point of the section observable.
- **`06_hot_keys.ipynb`**: Fixed a correctness bug in `DynamicSplitter`.
  When K=1 the original code wrote to the bare key, but once K grew
  `get_total` only scanned suffixed sub-keys — so the early writes
  were silently lost and the reported total was ~149 short. New
  version always writes to `{key}_{suffix}` (suffix=0 when K=1), so
  reads always find everything. Also swapped the hardcoded
  `"scaled from K=1 to K=8"` message for the actual final K value.

### 2026-04-19 (QA review, round 2)
- **`01_write_bottlenecks.ipynb`**: Setup cell now follows the repo's
  `.venv` kernel convention (uv sync + VS Code kernel picker + reload
  window fallback). Fixed off-by-one in the p95 latency calc.
- **`02_database_optimization.ipynb`**: Added two real-world tricks that
  were missing from the optimization ladder:
  - **UNLOGGED tables** — live benchmark comparing commit-per-row throughput
    with and without WAL writes.
  - **`execute_values`** — completes the insert-speed ladder
    (`executemany` → `execute_batch` → `execute_values` → `COPY`).
- **`03_sharding.ipynb`**: Added the **consistent hashing** section that
  the learning objectives promised but the notebook never showed.
  Includes a working `ConsistentHashRing` with virtual nodes and a
  side-by-side comparison of key movement when going 4 → 5 shards
  (~20 % with consistent hashing vs ~80 % with plain modulo).
- **`04_queues_load_shedding.ipynb`**: Added **dead-letter queues and
  backpressure**, with a runnable DLQ demo that correctly captures a
  poison message after N retries.
- **`05_batching_aggregation.ipynb`**: Added a wall-clock benchmark that
  times naive `UPDATE`-per-like against the Redis-aggregate-then-flush
  pattern, so the "10 000 likes → 10 DB writes" claim is concrete
  (observed ~200× fewer DB writes and ~1.4× faster end-to-end on a
  laptop).

## 2026-08-21 (correctness audit)

Read-only content audit of all six notebooks. Docker was **not** run; every
finding below was verified by reading, by re-deriving the arithmetic, or by
executing the pure-Python cells against a Redis stub.

### Defects fixed

- **`02_database_optimization.ipynb`** — the index-overhead benchmark did not
  measure index overhead. Inserting 10,000 rows with a Python `for` loop pays
  one network round-trip per row, and that cost is identical for both tables,
  so index maintenance showed up as **+2.7%** — pure noise — while the prose
  underneath confidently explained how expensive GIN-on-JSONB is. Rewritten to
  generate rows server-side (`INSERT … SELECT FROM generate_series`), 50k rows,
  varied JSONB payloads so the GIN index actually has work to do. Now asserts
  `slowdown > 20%`. Also deleted the now-unused `benchmark_inserts` helper.
- **`04_queues_load_shedding.ipynb`** — the priority-shedding demo printed
  `Dropped: 35 low-priority items`. Only **30** of them were low priority; the
  other 5 were medium. `shed_load` returned a bare count and the caller labelled
  it. It now returns a `{priority: count}` breakdown taken from the actual
  `ZPOPMIN` scores, prints both what was dropped and what survived, and says the
  quiet part out loud: priority shedding does not mean only unimportant things
  get dropped, it means the least important thing *still in the queue* goes
  first. Asserts the exact composition (`{"low": 30, "medium": 5}` dropped, all
  10 high-priority survivors).
- **`06_hot_keys.ipynb`** — `DynamicSplitter` claimed to "monitor write rate per
  key" but compared a **cumulative** write counter against the threshold. A
  cumulative counter only goes up, so K doubles forever: a key doing 1 write/sec
  would be split 64 ways after a day. The three-phase demo also had no notion of
  time, so "traffic increases over time" was an artefact of the counter, not a
  property of the input. Rewritten around a simulated clock and a windowed rate,
  with hysteresis and a merge-back path. Phase 1 (100 writes/sec) now
  deliberately leaves K=1 — and that is asserted, because it is exactly the
  assertion that catches the cumulative-counter bug.
- **`06_hot_keys.ipynb`** — `HotKeyDetector`'s `window_size` was a check
  cadence, not a window; counts were cumulative and `hot_keys` never cooled
  down. Renamed to `check_every` and documented both limitations (a real
  detector needs a decaying/sliding count, usually a count-min sketch).
- **`01_write_bottlenecks.ipynb`** — the "Index Overhead on Writes" cell defined
  `write_with_indexes()` and never called it: the section promised a measurement
  and delivered a list of index names. Removed the dead function, kept the
  inventory, and pointed at Notebook 2 where the cost is actually measured.
- **`02_database_optimization.ipynb`** — the `execute_values` cell was titled
  "execute_values vs execute_batch" but printed one number with nothing to
  compare it to. It now prints both and asserts the ordering.
- **`03_sharding.ipynb`** — `"China and India get 75% of writes!"` was hardcoded;
  the data says 74.3%. Now computed from the counts. Same cell reports an
  imbalance factor (3.7x) instead of asking you to eyeball a bar chart.
- **`03_sharding.ipynb`** — the hash-sharding cell built a `SimpleShardedDB`,
  monkey-patched `get_shard` onto it, then bypassed both and incremented the
  counters by hand. Now it actually routes through `db.write()`.
- **`05_batching_aggregation.ipynb`** — `sync_to_db` used `GETDEL`, which
  removes the counter *before* the `UPDATE` commits: a crash in that window
  loses the likes with nothing left to replay. Switched to read → commit →
  `DECRBY` the exact amount applied, which is at-least-once (a crash re-applies
  a delta rather than dropping one) and also lets a like that arrives mid-flush
  survive. Asserts the DB total equals the likes received.

### Gaps filled (each one the lab already claimed, in prose or in the README)

- **`03_sharding.ipynb`** — the notebook told you `timestamp` was a bad
  partition key and never showed it. New section shards 10,000 timestamp-ordered
  events three ways and measures the imbalance factor: range sharding on a
  monotonic key scores a perfect **1.00x on a historical backfill** and **4.00x
  on the next hour of traffic** — the failure mode is invisible to exactly the
  kind of benchmark teams run before shipping. Modulo scores 1.00x but destroys
  locality; hashing a non-monotonic key gets both.
- **`03_sharding.ipynb`** — new prose section on cross-shard transactions: the
  2PC round-trip diagram, a table of what it costs (2x latency, locks held
  across the network, blocking on coordinator failure), and the three ways
  production systems design the problem away instead.
- **`04_queues_load_shedding.ipynb`** — new section on what a write-behind queue
  loses on crash. `LPOP`-then-write is at-most-once and the gap between the two
  steps swallows items with no error and no leftover; `LMOVE` to an in-flight
  list plus `LREM` after the write is at-least-once. Both halves are executed
  and asserted (the naive path must lose exactly 1 of 5; the safe path must lose
  none), with the honest closing note that at-least-once buys you duplicates.
- **`05_batching_aggregation.ipynb`** — batching's latency cost was named in one
  line of prose and never measured. New deterministic event-time simulation
  sweeps the flush interval against a fixed arrival rate and prints DB
  writes/min beside mean and p99 staleness. It also shows the part that gets
  skipped: below the point where writes collide on the same key, batching buys
  nothing but latency.
- **`02_database_optimization.ipynb`** — "Cassandra is faster for writes" had no
  numbers behind it. New write-amplification cell: B-tree with 3 secondary
  indexes ≈ 328x, leveled LSM ≈ 22x — and the point that the *shape* matters
  more than the ratio (random and synchronous vs sequential and deferred).
- **`06_hot_keys.ipynb`** — the lab README promised "resharding without
  downtime" and no notebook covered it. New section runs the same
  write-arrives-mid-migration scenario through a naive copy (loses it silently)
  and through double-write → backfill → verify → cut over (doesn't), asserts
  both outcomes, and prices what double-writing costs for the duration.

### Determinism and assertions

- Seeded every RNG that fed a printed number (`random.seed` in notebooks 4, 5
  and 6; `SELECT setseed(0.42)` before the PostgreSQL partitioning insert).
- Added ~45 assertions across the six notebooks, each written so the lab fails
  loudly if it stops reproducing its own lesson rather than quietly printing a
  number nobody checks. Highlights: concurrency must beat a single writer by
  >1.5x; the insert ladder must stay a ladder (`COPY` < `execute_batch` <
  row-at-a-time); hash partitioning must land within 10% of even and `EXPLAIN`
  must prune to exactly one partition; consistent hashing must move <30% of keys
  where modulo moves >70%; the burst must shed exactly 500 writes; key splitting
  and merging must be lossless across every K transition.
- Deliberately **not** asserted: the `UNLOGGED` vs `LOGGED` speedup. On Docker
  Desktop the VM layer buffers `fsync`, so the gap is often near zero through no
  fault of the lab. Added a note saying so and asserting only the direction
  (`UNLOGGED` can never be materially slower).
