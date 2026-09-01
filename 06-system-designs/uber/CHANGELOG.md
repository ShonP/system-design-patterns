# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-21

Content-correctness pass. Every notebook now fails loudly if it stops reproducing its own lesson.

**Bugs fixed**

- **NB1 cell 15 claimed the opposite of its own output.** It printed "drivers close together share a
  longer common prefix", but `driver:3` sits 1.92 km from `driver:2` and shares only 3 geohash
  characters with it — fewer than `driver:4` (3.71 km) or `driver:5` (4.60 km), which share 4. A
  cell boundary runs between drivers 2 and 3. The cell now prints geohash, true distance and shared
  prefix length side by side and asserts the boundary effect is present.
- **NB2 `cleanup_stale_drivers` left ghost drivers matchable.** It only walked `drivers:last_seen`,
  so drivers 9 and 10 — planted in the geo set with *no* `last_seen` entry, and flagged
  "❌ UNKNOWN" one cell earlier — were never swept, while the cell went on to print "Stale drivers
  are gone". Cleanup now also evicts geo-set members with no timestamp at all, and asserts it.
- **NB2 adaptive-interval saving was overstated by ~2×.** Prose and summary claimed "~60%" and
  "50–60%"; the notebook's own arithmetic computes 35% (650k vs 1M updates/sec). The number is now
  interpolated from the computation, with a note on where the saving actually comes from.
- **NB2 interval table disagreed with the code.** The markdown said city driving → 3 s;
  `calculate_update_interval` returned 5 s. Table corrected to match, and the dead
  `elif speed < 80 / else` branch (both returned 10) collapsed.
- **NB3 `calculate_surge` docstring quoted pre-rounding numbers.** "ratio=2 → 1.4×" — the 0.25
  rounding step makes it 1.50×. Corrected, and the documented examples are now asserted.
- **NB3 fixed-vs-surge simulation had no notion of waiting.** The comment said riders "waited >2
  windows" but the code capped the queue at 40, which pinned the backlog to exactly 40 under both
  pricing rules and made the column useless. Replaced with real per-cohort ageing; served / gave-up /
  backlog now all separate the two rules (22→42 served, 178→110 lost, 50→30 waiting).
- **NB4 `request_ride` still had a TOCTOU inside the lock.** The candidate list was built before any
  lock was held and never re-read afterwards, so a driver claimed in the gap could be assigned twice.
  It now re-checks `drivers:available` after acquiring the lock.
- **NB4 cell 15 did not test what its heading promised.** "Prove that our locking prevents
  double-assignment by requesting two rides simultaneously" only raced two `SET NX` calls. It now
  races two full claims (insert ride → lock → re-check → SREM → assign) and asserts the database
  ends with exactly one ride holding driver #1.
- **NB4 cell 4 printed "❌ BUG" but never failed**, and never exercised the validator against a real
  row. Both fixed.

**Added**

- NB1: new "The Cell-Boundary Trap" section — a stdlib geohash encoder/decoder plus exact 8-neighbour
  expansion, showing that same-cell prefix search misses `driver:3` at 1.92 km *and* returns drivers
  outside the radius, and that 9 cells + an exact distance filter reproduces `GEOSEARCH` exactly.
- NB1: cross-check asserting the Redis geo index and the naive haversine scan agree on the top-3
  ranking and distances (catches swapped lat/lng and flat-Earth distance formulas).
- NB4: demonstration that a *stale* token release is a no-op — ride #300's expired lock cannot delete
  ride #400's replacement. The Lua safe-release added in April was never actually exercised.
- Assertions throughout: Redis-beats-PostGIS on both proximity search and write throughput, surge
  monotone in demand/supply ratio, surge curve peaks then falls back to 1.0×, fare = base × multiplier,
  demand counters not silently expired by their 120 s TTL, only fresh+available drivers in results.
- Honest limits: README gains a "What This Lab Does *Not* Model" section (small-sample surge noise,
  one-window surge lag, single-node Redis lock is not a correctness guarantee, nearest-first matching
  only). Matching notes added to the NB3 and NB4 summaries.

**Found by running the lab against real Docker**

- **NB3 `estimate_fare` quoted a price that was not base × multiplier.** Step 4 applied the surge to
  the *unrounded* base (`round(base_fare * surge, 2)`) while the receipt displayed
  `round(base_fare, 2)`, so the two figures printed for the rider did not produce the third:
  Downtown quoted \$200.66 where 40.13 × 5.0 is \$200.65. Rewritten to work in **integer cents** —
  round to cents once, then `(cents * round(surge * 4) + 2) // 4`, which is exact half-up rounding
  and never touches a float (`40.13 * 5.0` is `200.64999999999998` in binary, which is the second
  half of the bug). `estimate_fare` now also returns `base_cents`/`fare_cents` as the source of
  truth, guards that the surge really is a multiple of 0.25, and the assertion states the contract
  in cents. A paragraph on money-on-floats added to the section intro.
- **NB2's write benchmark was silently corrupting the fixture.** Cell 4 overwrote every row of
  `driver_locations` with random jitter around downtown and never put it back, so notebooks 3 and 4
  — and any re-run of notebook 1 — were reasoning about scrambled driver positions. It now
  snapshots the seeded coordinates, restores them after the benchmark, and asserts the restore.
- NB3: the surge caveat named the Castro pickup as the surprising one. That is only true for the
  seeded positions, so it is now derived from the computed estimates instead of hard-coded.

**Determinism**

- Seeded `random` in NB2 and NB4 so jittered positions and the 80% driver-accept roll are repeatable.

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
