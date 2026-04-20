# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- **Notebook 1**: Rewrote the Naive vs PostGIS benchmark so PostGIS clearly wins (~70x faster).
  Root cause of the old misleading numbers: users were all packed in LA (no room for
  the GIST index to prune), and `LIMIT 20` let the naive query stop early. The benchmark
  now scatters 100k users across the Western US, uses `COUNT(*)` instead of `LIMIT`,
  removes age/gender filters that let B-tree indexes short-circuit the scan, and reuses
  a single connection so connection-open time does not dominate the measurement.
- **Notebook 1**: Expanded summary with a comparison table of real-world geo backends
  (PostGIS, Elasticsearch `geo_distance`, Redis `GEO*`, Uber H3 / Google S2).
- **Notebook 2**: Added an explicit explanation of *why* Redis Lua scripts are atomic
  (single-threaded Redis) and a warning that long scripts block every other client.
  Added a scaling note that user-pair keys keep both swipe directions on the same
  shard in Redis Cluster.
- **Notebook 3**: Added a trade-offs table for Redis Pub/Sub (at-most-once, no
  persistence, per-channel ordering) and a "when Pub/Sub isn't enough" section pointing
  at Redis Streams, Kafka, and WebSocket+queue patterns.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
