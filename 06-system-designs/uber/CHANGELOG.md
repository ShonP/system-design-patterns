# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- **Bad→best progression added** to all notebooks per repo convention:
  - NB1: new "Approach 1: Naive Python Scan" section (Haversine + O(N) filter) before PostGIS.
  - NB3: new "A World Without Surge" executable comparison showing fixed-price backlog vs surge clearing the market.
  - NB4: new "Without a Lock: The Race Condition" deterministic demo showing double-assignment, introduced before the locking section.
- NB4: upgraded the lock primitive to token-based ownership + Lua-scripted safe release (prevents deleting another owner's lock after TTL expiry).
- NB4: added a short "Idempotency" callout explaining how idempotency keys prevent double-tap → double-ride bugs.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
