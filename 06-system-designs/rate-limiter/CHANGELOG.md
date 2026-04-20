# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Notebook 1: added **Leaky Bucket** section with runnable demo comparing Leaky vs Token Bucket behavior on bursts.
- Notebook 2: added **Sliding Window Log** implementation (exact accuracy at higher memory cost) — previously only mentioned in the README.
- Notebook 4: added **Tiered Limits** demo (free vs premium endpoint burst) and a **client-side exponential-backoff retry** example with jitter.
- `app/server.py`: middleware now maps `/api/premium` to the `premium` rule (it was silently using `default`). Added `NoScriptError` fallback so rate limiting still works after a Redis restart flushes the script cache.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
