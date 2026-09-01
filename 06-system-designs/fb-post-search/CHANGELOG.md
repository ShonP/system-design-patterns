# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20
- Lab 1: the LIKE vs tsquery vs Elasticsearch benchmark ran against ~500 rows, where
  ILIKE (4.5 ms) and the GIN index (4.3 ms) are indistinguishable — the notebook's
  central claim was asserted, not shown, and the query plan cell had to force
  `enable_seqscan = OFF` to make the index appear at all. Added a section that builds
  a 200,000-row `posts_bench` table and reruns the identical comparison: ~57 ms vs
  ~5 ms, an 11x gap, with the planner choosing the Bitmap Index Scan unaided. The
  table is dropped afterwards so Labs 2 and 3 are unaffected.
- Lab 3: **the two-stage retrieve-and-rerank demo was a no-op.** Elasticsearch's
  like counts were bulk-loaded straight from PostgreSQL, so "ES likes (approx)" and
  "real likes" were always identical and stage 2 never changed the ordering — while
  the prose claimed it was correcting a stale index. The demo now creates genuine
  staleness (two posts go viral in PostgreSQL without being reindexed), shows the
  re-rank pulling them from rank 7-8 into the top 5, asserts the order actually
  changed, and restores the counts. Added the trade-offs: the candidate window
  bounds what a re-rank can fix, and re-ranking on likes alone discards BM25.
- Lab 3: **added the missing pagination section.** The lab covered ranking but never
  paginated, in a system taking 10K posts/sec. Now demonstrates result-set drift for
  real — page 1, index 3 newer posts, page 2 with `from`/`size` repeats 3 of 5 rows —
  then fixes it with `search_after`, explains why the sort must be a total order,
  and shows Elasticsearch rejecting `from=10000` with the reasoning behind
  `index.max_result_window`. Trade-offs stated: no random access, still not a
  snapshot (point-in-time and its cost), and reverse paging needs a second cursor.
- Hygiene: all three notebooks had `kernelspec` `"Python 3"` instead of
  `"Python 3 (.venv)"`, and all shipped with saved outputs and execution counts
  (16/16/13 cells). Cleaned, and bumped to nbformat 4.5 with cell ids.
- README: added Functional / Non-Functional requirements and a capacity estimate.
  The estimate derives the ~135 TB inverted index from 9e13 postings, turns that into
  ~2,700 shards / ~200 nodes, and then confronts the consequence the README previously
  skipped — 10K searches/sec x 2,700 shards is 27M shard-queries/sec, so
  document-partitioned scatter-gather cannot work and you must route by time.
  Also quantifies the milestone like-update trick (14x fewer index writes) and states
  how much of the cache design depends on results not being personalized.


## 2026-04-20
- Pinned `elasticsearch` Python client to `<9.0.0` to stay compatible with the Elasticsearch 8.13 server used in `docker-compose.yml` (client 9.x rejects `body=` and talks a newer API).
- Fixed `psycopg2.extras.RealDictCursor` calls that used a positional arg; now use `cursor_factory=` so the notebooks actually run.
- Fixed an `_score` formatting crash in the ranking dashboard cell (Elasticsearch returns `_score=None` when results are sorted by a field).
- Reworked the PostgreSQL `EXPLAIN ANALYZE` cell to `SET LOCAL enable_seqscan = OFF` so beginners actually see the `Bitmap Index Scan on idx_posts_search` the surrounding narrative promises (the planner picks a seq scan on 500 rows).
- Added a **"Typo-Tolerant Suggestions (Fuzzy Matching)"** section to Notebook 2, showing edit-distance matching via Elasticsearch's completion-suggester `fuzzy` option — a real-world UX feature that was previously missing.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
