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
