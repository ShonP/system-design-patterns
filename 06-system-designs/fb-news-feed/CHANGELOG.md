# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Fixed reserved-word bug in `db/init.sql` (`offset` → `shift`) so the seed
  script actually runs against PostgreSQL.
- Notebook 1: rewrote the two benchmark cells to reuse a single DB
  connection so the measured speedup reflects query cost rather than
  connection-handshake overhead. Hybrid now caches the celebrity set.
- Notebook 2: interaction seed now targets users that user 1 actually
  follows (11, 25, 35, 37, 51) — earlier demo used IDs user 1 did not
  follow, so the ranked feed showed only the celebrity. Added a few
  recent posts from friends 11 and 25 so the ranked output surfaces a
  realistic mix of friends-and-celebrity. Cleanup reordered to respect
  the foreign-key dependency between `likes` and `posts`.
- Notebook 3: added a new **bad → best** section showing a sequential
  scan with `EXPLAIN ANALYZE`, then dropping vs re-creating the reverse
  index.
- Notebook 4: added a **pagination** section contrasting offset vs
  keyset pagination, with a runnable `ZREVRANGEBYSCORE` example.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
