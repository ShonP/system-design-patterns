# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Fixed NB1 three-user OT demo: replaced example with clearer positions so the
  final text reads naturally ("The brown fox and lazy dog jumps") instead of
  jammed-together words.
- Added **server-side role enforcement**: the doc server now rejects `edit`
  messages from users whose role is `viewer` (previously viewers could edit).
- Added a new permissions-demo cell to NB3 that verifies a viewer is blocked
  by the server — reinforcing "never trust the client".
- Added a new diff-between-versions cell to NB4 that uses `difflib` to show
  what changed between two snapshots (how "Show revision history" works).

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
