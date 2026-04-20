# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

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
