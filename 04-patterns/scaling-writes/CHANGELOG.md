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
