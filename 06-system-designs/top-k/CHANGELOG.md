# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-21
- Notebook 2: **fixed a real correctness bug in `TopKHeap`.** The eviction test
  compared a newcomer against `heap[0]`, which with lazy deletion is frequently
  a *stale* entry holding an out-of-date, far-too-low count. A newcomer that
  beat the stale root but not the true minimum was admitted anyway, evicting a
  genuine heavy hitter. A 4,000-push randomised check found 570 invariant
  violations before the fix and 0 after. `_clean()` now runs before the
  comparison.
- Notebook 2: added `_compact()` so the lazily-deleted heap stays at O(K)
  instead of growing one entry per event. Without it the heap ended up O(n)
  and the notebook's "O(log K) per event" claim was not true of its own code.
- Notebook 2: added a regression cell that reproduces the stale-root eviction
  in five lines and asserts the top-K invariant over a randomised stream.
- Notebook 2: the "K vs performance" experiment ran on the 50-video seed data,
  where every K >= 50 never evicts and therefore measures the identical
  computation. It now runs on a seeded 200K-event / 5,000-video stream where K
  actually binds, and asserts both the heap bound and that K=5 -> K=1000 costs
  less than 3x.
- Notebook 2: the performance chart plotted a full 488-event stream ingest next
  to single SQL queries under the title "Query Performance Comparison". It now
  compares read latency only (heap read vs the two SQL reads) and reports the
  ingest cost separately in prose.
- Notebook 2: the 24h-window SQL cell claimed the window query is slower; at
  488 rows the difference is scheduling noise. The prose now says so and
  explains where the structural gap actually appears.
- Notebook 1: added a **sizing section** — `w = ceil(e/eps)`, `d = ceil(ln(1/delta))`
  — that verifies the guarantee against real numbers on the 1M-event stream,
  asserting no undercounts and that the fraction of items exceeding the
  `eps*N` budget stays under delta. Spells out that the CMS bound is
  **one-sided** (no `+/-` error bar) and scales with N rather than with the
  item's own count.
- Notebook 1: the prose claimed the #1 video always has the *lowest* percentage
  error; in the 2000x4 config it ranks second. Softened to "far below average"
  and backed by an assertion. Also corrected "the Large config uses only a few
  hundred KB" — it is 977 KB, against 1.9 MB for the equivalent dict.
- Notebook 1: added undercount assertions to both accuracy cells, so the
  one-sided guarantee fails loudly instead of being asserted only in prose.
- Notebook 3: **added the missing merge lesson.** The lab claimed merging
  shard-local top-K lists is "guaranteed" correct without saying that the
  guarantee comes from sharding by `video_id`. A new section reproduces the
  failure when events are sharded by ingest server instead — a broadly popular
  "slow burn" video that is #1 globally and top-K on no shard vanishes from the
  merge entirely — then shows Count-Min Sketches merging element-wise, with an
  assertion that the merged table is bit-for-bit the sketch built over the whole
  combined stream.
- Notebook 3: the HyperLogLog demo ran at a few dozen unique viewers per video,
  where Redis keeps the HLL in its sparse encoding and `PFCOUNT` is exact — so
  it printed 0% error while the prose claimed ~0.8%. Now runs at 1K/10K/100K
  cardinality where the approximation actually does work, reports the real key
  size against a SET of the same ids, and notes that HLL error is **two-sided**
  unlike CMS.
- Notebook 3: the tumbling-vs-sliding comparison picked "now" as the newest
  event, landing at a random point in the hour — sometimes with no visible gap
  at all. It now picks a reference early in an hour and asserts the sliding
  window strictly beats the partial bucket, plus an honest note that the seed
  data's single-digit window counts make the rankings noise.
- Notebook 3: reconciled the storage estimate with Notebook 1 (54 GB raw vs
  272 GB in a Python dict — the lab previously quoted 54, 64 and 268 GB for
  the same quantity), and fixed a nonsensical "1 hour of content per second"
  comment.
- Notebooks 1-3: added assertions throughout so the labs fail loudly if they
  stop reproducing their own lessons — one-sided CMS error, heavy-hitter
  recovery, `eps*N` budget, heap bound, shard-merge correctness under key
  sharding, ZSET exactness, and the <50 ms read target.
- README: corrected the naive-storage row and documented the epsilon/delta
  sizing rule and the mergeable-state distinction.

## 2026-04-20
- Switched Redis image to `redis/redis-stack-server` so the `CMS.*` and
  `TOPK.*` commands used in Notebook 1 actually work out of the box.
- Notebook 1: added a **1M-event Zipfian stream** demo that exposes real
  Count-Min Sketch overcount behaviour (hidden by the tiny seed data), plus
  a bonus section using Redis' purpose-built `TOPK` data structure.
- Notebook 1: rewrote the memory-comparison cell to explain why CMS *loses*
  to a plain dict at lab scale (fixed overhead) and only pays off at scale.
- Notebook 2: replaced hard-coded `log₂(1000)` with a computed value and
  added a short note about the lazy-deletion heap's growth behaviour.
- Notebook 3: added a **tumbling vs sliding window** side-by-side demo, an
  **HyperLogLog** demo for counting unique viewers, and a real-world
  examples table (Twitter, Spotify, Reddit, Amazon, Google Trends).
- README: documented that the lab now requires Redis Stack for the Bloom
  module family.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
