# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19
- QA pass: added `00_intro.ipynb` (why rate limit, 429 / Retry-After headers) and `04_distributed_and_backoff.ipynb` (Redis-style shared counter, client-side exponential backoff with full jitter).
- Rewrote `01`, `02`, `03` to follow bad → best progression and added matplotlib visualizations (allowed/denied timelines, token-vs-leaky pacing, fixed-vs-sliding boundary burst).
- Added per-key token bucket example and O(1) sliding-window-counter (Cloudflare-style hybrid).
- Updated `README.md` to list all five notebooks and the concepts they cover.

## 2026-04-18
- Scaffolded `Rate Limiting And Throttling` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
