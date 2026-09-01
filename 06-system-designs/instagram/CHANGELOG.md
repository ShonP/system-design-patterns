# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-21

Content-correctness review. Several cells ran cleanly while demonstrating
nothing, or while doing something other than what the prose above them claimed.

- **Fix**: Notebook 2's "celebrity problem" cell only *printed follower counts*
  and asserted in prose that fan-out on write is expensive. It now **measures**
  the pipelined per-follower ZADD cost at 100/1K/10K followers, verifies the cost
  actually scales with follower count, and projects that unit cost onto each
  celebrity's real follower count (including Ronaldo's 600M).
- **Fix**: Notebook 1's `generate_thumbnails` used `Image.thumbnail()`, which
  only preserves aspect ratio. The table above it promised square variants, so an
  800×600 upload produced a "150×150 thumbnail" that was actually 150×112. Now
  centre-crops with `ImageOps.fit`, and never upscales past the source's short side.
- **Fix**: Notebook 4's `score_post` read `author_avg_likes`, which no candidate
  query ever supplied. The `.get()` fallback silently made author quality a copy
  of engagement — the documented 0.4/0.3/0.2 weighting was really 0.6/0.3.
  Both candidate queries now compute the author's average like count.
- **Fix**: Notebook 4's diversity bonus was applied while scoring, in whatever
  order SQL returned rows, *before* the final sort — so it could not prevent
  author clustering. Diversity is a property of the output list, so it is now a
  greedy re-rank pass (`rerank_for_diversity`) applied while building that list.
- **Fix**: Notebook 3's story ring was demoed with user 10, who follows neither
  of the two users the notebook had created stories for. The ring was always
  empty and printed a misleading "try running create_story first". Added
  `load_active_stories_into_redis()` (the seeded stories only ever existed in
  PostgreSQL) and asserted the ring is non-empty.
- **Fix**: Notebook 3's `get_story_ring` docstring promised "unseen first, then
  by recency" and a comment claimed to check views; neither was implemented, and
  the function ran one Redis call and one SQL query per followed user. Now
  actually orders unseen-first/newest-first and batches into 2 SQL queries plus
  3 pipelined Redis round-trips.
- **Fix**: Notebook 3's TTL demo slept 30 wall-clock seconds and could finish
  without ever observing the key expire, with nothing asserting that it did.
  Now uses a 3s TTL, polls until Redis removes the key, and fails loudly otherwise.
- **Fix**: Notebook 3's `create_story` computed `expires_at` from the notebook
  host's `datetime.now()` while `created_at` came from the database clock, so
  every story's real lifetime was off by the host↔container clock skew.
  Computed in SQL now, with an assertion that Redis TTL and `expires_at` agree.
- **Fix**: Notebook 3's `cleanup_expired_stories` opened a PostgreSQL connection
  it never used, and had nothing to sweep so it proved nothing. It now plants a
  dangling index entry first and asserts the sweep removes it while leaving live
  stories alone.
- **Fix**: Notebook 1's `confirm_upload` leaked its connection on both error
  paths, and the "file not found in storage" branch was never exercised. Added a
  negative-path demo that confirms a post whose client never uploaded.
- **Fix**: Feed and Explore queries ignored `media_upload_status`, so the
  `pending` posts Notebook 1 creates could be served in a feed — contradicting
  Notebook 1's own claim that only `complete` posts appear. Filter added to the
  read path, the write path's hydration query, and both Explore candidate queries.
- **Fix**: Notebook 4's `record_explore_interaction` ran one `SELECT` per cached
  post (200 round-trips per tap), counted the just-liked post among the "other
  posts from this author" it boosted, and printed "scores updated" without ever
  showing a score change. Batched into one query, the engaged post is now dropped
  from the candidate set, and before/after scores are printed and asserted.
- **Added**: Notebook 2 — **cursor pagination**. Offset pagination on a feed that
  is being written to duplicates the page boundary on every insert and skips
  items on every delete. The lab now reproduces the duplicate, then fixes it with
  keyset pagination. The cursor breaks score ties on the member string because
  that is how Redis itself orders ties — an int tie-break silently skips items.
- **Added**: Notebook 2 — **feed invalidation**. A precomputed feed is a cache:
  unfollowing someone leaves their posts in the follower's Redis feed forever.
  The lab reproduces the stale feed and shows both fixes (ZREM on the write side,
  filter on the read side), then restores state so the notebook re-runs.
- **Added**: Notebook 2 — the arithmetic behind the 100K celebrity threshold:
  it is a posting-rate-vs-read-rate crossover, not a fixed follower count.
- **Added**: Notebook 4 — **`like_count` under concurrency**. Every ranking
  function in the notebook reads that denormalised counter, and nothing kept it
  correct. Added a barrier-synchronised 25-thread demo where read-modify-write
  loses 24 of 25 likes and `SET like_count = like_count + 1` loses none.
- **Added**: Assertions throughout all four notebooks, so a lab that stops
  reproducing its own lesson fails loudly instead of printing plausible output —
  including fan-out completeness, hybrid feeds drawing on both halves, view-count
  dedup across Redis *and* PostgreSQL, and Explore never surfacing followed
  accounts or already-liked posts.
- **Added**: "What This Toy Version Does NOT Do" sections to Notebooks 2-4 and
  the README (no async fan-out, no sharding, no ranking, no embeddings, no
  integrity filtering, no S3 cleanup after story expiry).

## 2026-04-20
- **Fix**: `init.sql` used the PostgreSQL-reserved keyword `offset` as a column alias,
  which silently aborted the entire seed script — seeding no follows, posts, likes, or
  interactions. Renamed the alias to `shift` so the seed now loads ~180 posts, ~500
  likes, 2,000 interactions, and ~2,200 precomputed feed entries.
- **Fix**: Notebook 4 used `similar` (a PostgreSQL-reserved word) as a CTE name, causing
  a syntax error in `find_similar_users`. Renamed the CTE to `similar_users`.
- **Fix**: Notebook 4's `get_popular_posts` embedded `%s` inside a quoted interval
  literal. Switched to the safer `(%s || ' hours')::interval` form.
- **Fix**: Notebook 2 passed `Decimal` values (from `extract(epoch …)`) to Redis
  `ZADD`, which only accepts bytes/str/int/float. Added explicit `float(...)` casts
  in `fan_out_on_write`, `create_post_hybrid`, and `populate_redis_feeds`.
- **Added**: Notebook 3 now opens its expiration discussion with a "bad practice"
  cron-polling example, matching the repo's bad→best progression convention.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
