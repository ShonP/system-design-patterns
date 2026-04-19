# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19
- Fixed stale setup paths (`deep-dives/time-series-databases` → `03-technologies/databases/time-series-databases`) in README and all three notebooks.
- **Notebook 1**: Added a bad → better → best ingestion section comparing one-row `INSERT` loops, `executemany`, and `COPY FROM stdin` on 5,000 rows. Added a cardinality-explosion numeric demo after the tags-vs-fields discussion.
- **Notebook 2**: Added sections on gap-filling (`time_bucket_gapfill` + `locf()` / `interpolate()`), `first()`/`last()` for counter-style deltas, and rate-of-change with the `LAG()` window function. Updated the Key Takeaways accordingly.
- **Notebook 3**: Added a native-compression section (enable → policy → per-chunk stats → hypertable-level compression ratio) with bad-vs-best trade-off table. Updated the data-lifecycle diagram and Key Takeaways to include compression.
- Silenced the pandas "SQLAlchemy connectable" `UserWarning` in the setup cells so output stays clean.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
