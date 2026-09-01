# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-21
- **Fixed a seed-data bug that made every geospatial comparison in Notebook 1 meaningless.**
  `db/init.sql` filled `latitude`/`longitude` and the PostGIS `location` column from *separate*
  `random()` calls, so each business sat at two different points. `ST_DWithin` reads `location`,
  the naive bounding box reads the columns, and Elasticsearch is loaded from the columns — the
  three approaches were quietly answering different questions. `location` is now derived from the
  stored columns in a single `UPDATE` after the insert.
- Added `SELECT setseed(0.42)` to `db/init.sql` so `docker compose down -v && up -d` rebuilds
  essentially the same 500 businesses and 3,000 reviews rather than a fresh random world.
  Previously every rebuild produced different numbers and no printed result could be compared
  across runs.
- Added a **data-integrity guard** to Notebook 1 that detects a `location` / lat-lon disagreement
  (which is what an existing Postgres volume seeded by the old `init.sql` still contains),
  repairs it in place, and then asserts.
- **Notebook 1: the naive bounding box was wrong, and the notebook never said so.** It used
  `delta = 0.018` on both axes, but at latitude 40.758 that is ~2,000 m north–south and only
  ~1,520 m east–west, so it silently dropped businesses due east and west of the user; the
  corners, at ~2,510 m, returned businesses outside the radius. Added a section that reproduces
  **both** failure modes deterministically with two probe points measured by PostGIS, then fixes
  the box with `lon_delta = lat_delta / cos(latitude)` and shows the exact second pass. The
  prefilter deliberately divides by the *smallest* metres-per-degree (110,574 m, the equatorial
  meridian degree) plus a 1% margin, so the box is guaranteed to contain the circle on the WGS-84
  spheroid rather than merely on a sphere.
- **Notebook 1: "PostGIS uses an Index Scan instead of a Sequential Scan!" was not necessarily
  true.** At 500 rows the planner may correctly prefer a sequential scan. The cell now prints the
  planner's own choice *and* the plan with `enable_seqscan = off`, asserts the GIST index is
  usable, and says plainly that the index wins asymptotically, not on toy data.
- **Notebook 1: the benchmark opened a fresh Postgres connection inside the timed loop**, so the
  Postgres rows measured `psycopg2.connect()` rather than the query. It now reuses one connection,
  like the long-lived Elasticsearch and Redis clients it was being compared against.
- **Notebook 2 claimed a lost-update bug that its own code did not have.** `submit_review_realtime`
  puts the running-average arithmetic inside a single `UPDATE`, and Postgres re-evaluates `SET`
  expressions against the updated row under `READ COMMITTED` — so it was already safe. Added a
  genuine application-side read-modify-write (`submit_review_lost_update`) that loses reviews, and
  a control run proving the single-statement version does not. Both use a `threading.Barrier`
  instead of a tuned `sleep`, so the race is forced deterministically on any machine.
- **Notebook 2: the concurrency test could not fail.** It printed "✅ optimistic locking worked" or
  "⚠️ small rounding difference" and continued either way — the second branch would have described
  genuine data loss as rounding. It now asserts, forces maximum contention with a barrier, and
  additionally asserts that the retry path was actually taken (`retries >= writers - 1`), so a
  degenerate zero-contention run fails loudly.
- **Notebook 2: the running average really does drift**, because `avg_rating` is `DECIMAL(3,2)` and
  each update feeds its own rounded output back in. Rather than hide that behind a loose tolerance,
  added a section that stores an integer `rating_sum` alongside `num_reviews` and derives the
  average from it — commutative, retry-free, and asserted to match a full recomputation *exactly*.
  `rating_sum` is now part of `db/init.sql`; the notebook adds and backfills it on existing volumes.
- **Notebook 2: nothing ever called `invalidate_business_cache`.** The cache section defined it and
  moved on, so a review could be written correctly and the page would still show the old rating for
  the full 300 s TTL. Added a demonstration that reproduces the stale read, asserts it, then fixes
  it — and explains why cache invalidation deletes rather than overwrites.
- **Notebook 3: two `function_score` comments were wrong.** "0-5 scale → 1-2x multiplier" described
  a term that is actually `log10(1 + 0.2 × rating)` ∈ [0, 0.30], and "score drops to 50% at 2km" was
  off by the `offset` — a gaussian decay reaches `decay` at `offset + scale`, i.e. 2.5 km. Both
  corrected, and a new section recomputes Elasticsearch's `_score` from scratch in Python (BM25 ×
  weighted log/gauss terms) and asserts it matches to within 0.02%.
- **Notebook 3: the search index and the source of truth could diverge with nothing to notice.**
  Notebook 2 writes reviews straight to Postgres and Elasticsearch never hears about them, so every
  ranking demo could be scoring on stale ratings. Added a section that deliberately creates a fresh
  divergence, audits both stores, re-indexes the difference, and asserts convergence — the
  reconcile pass the README's CDC box was previously only claiming.
- **Notebook 3: the caching benchmark called `r.flushdb()`**, which wipes the whole Redis database
  including the other notebooks' keys (and any other lab sharing the container). Replaced with a
  targeted `ranked:*` delete, plus assertions that the second search was actually a cache hit.
- Noted honestly in Notebook 3 that the three-way "ranking strategy" comparison is not like-for-like:
  strategies 1 and 2 search all five cities while strategy 3 also applies a 10 km geo filter.
- Added **"What this toy does NOT do"** sections to all three notebooks and the README (no
  antimeridian or polar handling, no geohash cell-neighbour logic, no review edits or deletes, no
  relevance evaluation, no incremental CDC), and rewrote the Notebook 2 summary table to say which
  approaches are concurrency-safe and which are exact.

## 2026-04-20
- Fixed `docker-compose.yml` to use the PostGIS-enabled Postgres image (`postgis/postgis:16-3.4`) — the previous `postgres:16` image lacked the `postgis` extension and caused `init.sql` to fail on startup, so the lab could not run end-to-end.
- Added `CREATE EXTENSION IF NOT EXISTS pg_trgm` to `db/init.sql` — `init.sql` already referenced `gin_trgm_ops`, but the extension was never enabled.
- Pinned `elasticsearch` to `>=8.13.0,<9` in `pyproject.toml` — the unbounded requirement pulled in the 9.x client, which rejects the 8.13 server as incompatible.
- Fixed `row[0]` accesses in the `EXPLAIN ANALYZE` cells of notebooks 1 and 2 — those cursors use `RealDictCursor`, so plan rows must be accessed via `row['QUERY PLAN']`.
- Added an **Autocomplete (search-as-you-type)** section to Notebook 3 with a runnable `match_phrase_prefix` demo that simulates a user typing letter-by-letter.
- Verified all three notebooks execute top-to-bottom with `uv run jupyter nbconvert --execute`.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
