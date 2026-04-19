# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

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
