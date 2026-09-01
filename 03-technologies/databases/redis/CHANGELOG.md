# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19
- Renamed `pyproject.toml` project name to `redis-deep-dive` so it doesn't conflict with the `redis` PyPI dependency (`uv sync` was failing).
- Fixed `GEOADD` call in notebook 1 to use a flat list (the redis-py API requires `[lon, lat, name, ...]`, not a list of tuples).
- Reworked Sentinel section in notebook 4 so it works from the host machine: added a small `host_addr()` helper that maps Sentinel-reported docker addresses (hostnames or container IPs) to host-mapped ports. The failover demo now reliably succeeds end-to-end.
- Added `sentinel resolve-hostnames yes` / `sentinel announce-hostnames yes` to all three Sentinels in `docker-compose.yml` (without these the Sentinels failed to start when the master is identified by hostname).
- Extended notebook 3 with three new "bad → best" sections:
  - Production-safe distributed lock using `SET NX EX` + unique token + Lua compare-and-delete release.
  - Sliding-window rate limiter compared deterministically against the fixed-window version (shows the boundary-burst attack).
  - Cache stampede prevention with a single-flight `SET NX` recompute lock + TTL jitter.
- Added a new notebook 5 covering missing topics: pipelines, `MULTI`/`EXEC` transactions and `WATCH` optimistic locking, Lua scripting (token-bucket limiter), RDB vs AOF persistence, Bitmaps for DAU, and HyperLogLog for unique counts.

## 2026-04-19
- QA pass: ran all 5 notebooks end-to-end against the live Docker stack.
- Notebook 4: connection cell now auto-detects which node is master (via
  `INFO replication` on ports 6380/6381/6382) instead of hardcoding `:6380`.
  Makes the notebook idempotent — re-running after a previous failover demo
  no longer crashes with `ReadOnlyError`.
- Fixed stale setup paths (`cd 03-technologies/databases/redis` → `cd 03-technologies/databases/redis`)
  in notebooks 1–4.
- README: corrected notebook filenames, added notebook 5, added a "re-run
  notebook 4" reset command, replaced the obsolete `redis-deep-dive` kernel
  registration step with the repo-standard `.venv` kernel convention.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
