# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19
- **Notebook 1** — Fixed a foreign-key violation in the cleanup cell that crashed the
  notebook on first run (cleanup now deletes `clicks` before `urls` and scopes itself
  to non-seed rows).
- **Notebook 1** — Added a Base62 **decode** function with a roundtrip sanity check so
  learners see why the counter approach is reversible.
- **Notebook 1** — Added a short "Other ID Strategies" section covering Ticket Server,
  Snowflake, UUIDs, and pre-generated Key Generation Services.
- **Notebook 2** — Added a **negative caching** section that defends against cache
  penetration by caching 404s with a short TTL.
- **Notebook 2** — Added a **custom aliases (vanity URLs)** section that actually uses
  the `custom_alias` column from the schema, with validation and reserved-word checks.
- **Notebook 2** — Made cleanup FK-safe and comprehensive (clears all non-seed rows).
- **Notebook 3** — Added a **real-time Top-N leaderboard** section using a Redis
  sorted set (`ZINCRBY` / `ZREVRANGE`) — demonstrates an O(log N) dashboard widget.
- Verified all three notebooks execute end-to-end against the docker-compose stack.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
