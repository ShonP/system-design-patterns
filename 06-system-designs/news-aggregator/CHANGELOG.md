# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- **Notebook 1 (RSS crawling)**: added bad→best framing for polling schedules (naive global interval vs per-feed priority queue) and a new "Being a Polite Crawler" section covering `If-Modified-Since` / `ETag` conditional GET, `robots.txt`, and User-Agent etiquette with a runnable feedparser demo.
- **Notebook 2 (dedup & ranking)**: major rewrite of the deduplication story.
  - Reframed SHA-256 as "exact dedup after normalisation" (not near-duplicates).
  - Introduced bag-of-words Jaccard as the primary near-duplicate demo (works on short rewritten news text where 3-gram shingling fails).
  - Added an empirical similarity-score table to justify the 0.3 threshold.
  - Hardened `find_near_duplicates` with greedy rep-guard clustering (avoids over-merging by transitive union-find), min-shared-tokens guard, min-token-set guard, URL stripping, and an expanded boilerplate list — fixes a false-positive cluster of Hacker News articles.
  - Repositioned word-shingling as an aside that captures word order.
  - Added a conceptual MinHash+LSH section with a ~128-hash signature demo, verifying the MinHash estimate matches the true Jaccard.
- **Notebook 3 (personalised feed)**: added a "Cold-Start Problem" section with a runnable trending-feed fallback for brand-new users, and a brief "Collaborative Filtering" section (user-user, item-item, matrix factorisation) explaining when to go beyond content-based scoring.
- All three notebooks re-executed end-to-end against the docker stack to verify they run without errors.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
