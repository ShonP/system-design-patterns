# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Pinned `elasticsearch` Python client to `<9.0.0` to stay compatible with the Elasticsearch 8.13 server used in `docker-compose.yml` (client 9.x rejects `body=` and talks a newer API).
- Fixed `psycopg2.extras.RealDictCursor` calls that used a positional arg; now use `cursor_factory=` so the notebooks actually run.
- Fixed an `_score` formatting crash in the ranking dashboard cell (Elasticsearch returns `_score=None` when results are sorted by a field).
- Reworked the PostgreSQL `EXPLAIN ANALYZE` cell to `SET LOCAL enable_seqscan = OFF` so beginners actually see the `Bitmap Index Scan on idx_posts_search` the surrounding narrative promises (the planner picks a seq scan on 500 rows).
- Added a **"Typo-Tolerant Suggestions (Fuzzy Matching)"** section to Notebook 2, showing edit-distance matching via Elasticsearch's completion-suggester `fuzzy` option — a real-world UX feature that was previously missing.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
