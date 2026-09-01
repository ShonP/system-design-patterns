# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (repo-wide verification pass)
- **Fix**: `timescaledb_information.chunks` has no `total_bytes` column in TimescaleDB 2.x, so the chunk-size queries in notebooks 1 and 3 failed with *"column total_bytes does not exist"*. They now join `chunks_detailed_size()`.
- **Fix**: `CALL run_job((SELECT job_id ...))` is rejected by Postgres (*"cannot use subquery in CALL argument"*). Added a `run_job_now(proc_name)` helper that looks the id up first.
- **Fix**: the `run_exec` helper set `autocommit` *after* `with psycopg2.connect(...)` had already opened a transaction, so statements TimescaleDB refuses to run inside one (`CALL refresh_continuous_aggregate`, `CALL run_job`) failed with `ActiveSqlTransaction`.
- **Fix**: the hierarchical continuous aggregate grouped by `bucket`, which binds to the source column rather than the `time_bucket(...)` alias -- TimescaleDB then rejected the view with *"continuous aggregate view must include a valid time bucket function"*. Now groups by the expression.
- **Fix**: the continuous-aggregate size query selected `materialization_hypertable_size`, which does not exist; it now resolves `materialization_hypertable_name` to a regclass and measures it.
- All 3 notebooks now execute end-to-end (previously 1 of 3). Note Grafana publishes on host port **3000**, which commonly collides with a local dev server -- see `tools/check_ports.py`.

## 2026-04-19
- Fixed stale setup paths (`03-technologies/databases/time-series-databases` → `03-technologies/databases/time-series-databases`) in README and all three notebooks.
- **Notebook 1**: Added a bad → better → best ingestion section comparing one-row `INSERT` loops, `executemany`, and `COPY FROM stdin` on 5,000 rows. Added a cardinality-explosion numeric demo after the tags-vs-fields discussion.
- **Notebook 2**: Added sections on gap-filling (`time_bucket_gapfill` + `locf()` / `interpolate()`), `first()`/`last()` for counter-style deltas, and rate-of-change with the `LAG()` window function. Updated the Key Takeaways accordingly.
- **Notebook 3**: Added a native-compression section (enable → policy → per-chunk stats → hypertable-level compression ratio) with bad-vs-best trade-off table. Updated the data-lifecycle diagram and Key Takeaways to include compression.
- Silenced the pandas "SQLAlchemy connectable" `UserWarning` in the setup cells so output stays clean.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
