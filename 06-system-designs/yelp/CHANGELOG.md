# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

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
