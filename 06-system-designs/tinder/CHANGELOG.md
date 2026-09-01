# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-21
- **Notebook 1**: Fixed a false claim in the feed demo. The recap said James Wilson was
  missing from Emma's stack because she had already swiped on him — he is 23 km away and
  Emma's radius is 15 km, so the *location* filter removed him at Step 1 and the
  `NOT EXISTS` already-swiped clause was excluding nobody at all. The notebook now says
  which filter did the work, inserts a swipe on a candidate that is actually in range so
  the exclusion has something to do, and asserts that Step 1 minus the final feed is
  exactly that one profile.
- **Notebook 1**: The bounding-box section asserted "the box includes corners farther than
  the radius" in prose only. It now diffs the box result set against the PostGIS result set,
  prints the offending user with their real distance, and fails if the two ever agree.
  Also documented that the chosen `0.09°` latitude delta (9.99 km) makes the box *clip* the
  circle due north and south — it is not a superset either.
- **Notebook 1**: Seeded the RNG for the 100k-user benchmark dataset; asserted PostGIS beats
  the unindexed Haversine scan by >5x; asserted the `EXPLAIN ANALYZE` plan actually names
  `idx_users_location` (the cell told you to look for it but never checked). Cleanup cell
  said it was removing "10,000 test users" when it inserts 100,000, and now also removes the
  demo swipe it added.
- **Notebook 2**: The race-condition demo relied on a `time.sleep(0.1)` landing right, and
  printed "if a match was detected, the timing worked out" if it did not reproduce. It now
  synchronises the two threads on a `threading.Barrier` so both complete their check before
  either writes — deterministic — and asserts that both swipes were stored and neither side
  detected the match. The comment above it named the wrong pair of users (Mia/Noah) from
  the pair the code actually uses (Luna/Oliver).
- **Notebook 2**: The atomic-swipe proof only checked that *at least one* side saw the match.
  Atomicity gives the stronger property: **exactly one**. Two detections would mean two
  "It's a match!" notifications and two match inserts. The trial loop now records detections
  per trial and asserts every trial is exactly 1.
- **Notebook 2**: New section — **the retried swipe**. The Lua script was atomic but not
  idempotent: replaying the same swipe re-runs `HSET`/`HGET` and re-fires the match, so a
  client retry produced a duplicate match event and a duplicate push. The section reproduces
  that, then fixes it with a v2 script that reads the previous value of the swiper's own
  field and reports a replay, while still treating a genuine left → right change of mind as
  a new decision.
- **Notebook 2**: Cleanup deleted rows from `matches` without first deleting the
  `notifications` that hold a foreign key into them — it blew up with an FK violation if
  Notebook 3 had run. Seeded the benchmark RNG and asserted its P99.
- **Notebook 3**: Every Pub/Sub subscriber thread iterated `pubsub.listen()`, which blocks
  forever after the last message; the deadline check inside the loop never ran again, so each
  demo leaked a thread plus a Redis connection for the life of the kernel and only "finished"
  because of `join(timeout=...)`. All four listeners now poll `get_message()` against a
  deadline and exit; threads are daemons; and the notebook waits on `PUBSUB NUMSUB` instead
  of guessing with `time.sleep` before publishing.
- **Notebook 3**: Adopted the idempotent swipe script, and made match creation the second
  idempotency guard — `INSERT ... ON CONFLICT DO NOTHING RETURNING id` now actually fetches
  its result, so only the request that *created* the match sends notifications. The
  end-to-end demo resets its own pair state, then replays Noah's swipe and asserts no second
  match and no duplicate notification rows.
- **Notebook 3**: The latency benchmark printed "Sub-millisecond delivery!" unconditionally,
  whatever it measured. It now reports the measured P50 and only makes the sub-millisecond
  claim when the number supports it, asserts all 500 messages arrived, and asserts a P99
  ceiling. The online/offline demo asserts 0 listeners before subscribing and 1 after.
- **README**: Added a "What this lab does *not* model" section — the already-seen set lives
  in Postgres rather than a Redis set or Bloom filter (and what a Bloom filter's false
  positives actually cost: a profile silently never shown again), no feed prefetch, static
  locations, no sharding.

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
