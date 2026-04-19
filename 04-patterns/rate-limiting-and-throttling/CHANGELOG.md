# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19 (later)
- QA re-review: re-executed all notebooks end-to-end — all pass.
- **Fixed** a correctness bug in `04_distributed_and_backoff.ipynb`: the simulated shared store recorded rejected requests, inflating the window and starving future traffic. Replaced with an atomic `check_and_add` and added a Redis-ready Lua script (with unique-member note).
- **Added** GCRA (Generic Cell Rate Algorithm) section to `02_leaky_bucket.ipynb` — the one-timestamp leaky bucket used by Redis `redis-cell`, Shopify, CDNs. Clear caveat that it's admission-control, not output-smoothing.
- **Added** observability section to `05_concurrency_and_practice.ipynb` — which metrics to emit (allowed/denied counters, retry-after histogram, store-error counter, heavy-hitter sampling) and why labeling metrics with high-cardinality keys is a trap.
- **Added** a real-world limits table to `00_intro.ipynb` (GitHub, Stripe, Discord, AWS, Cloudflare…) so beginners see concrete numbers and which algorithm each vendor uses.

## 2026-04-19
- QA review: verified all notebooks execute cleanly end-to-end; added `05_concurrency_and_practice.ipynb` covering concurrency limits (semaphore), cost-based limits, where to enforce (edge / gateway / service), fail-open vs fail-closed, and how to choose the limit key (IPv4 NAT, IPv6 `/64`, `X-Forwarded-For` traps).
- QA pass: added `00_intro.ipynb` (why rate limit, 429 / Retry-After headers) and `04_distributed_and_backoff.ipynb` (Redis-style shared counter, client-side exponential backoff with full jitter).
- Rewrote `01`, `02`, `03` to follow bad → best progression and added matplotlib visualizations (allowed/denied timelines, token-vs-leaky pacing, fixed-vs-sliding boundary burst).
- Added per-key token bucket example and O(1) sliding-window-counter (Cloudflare-style hybrid).
- Updated `README.md` to list all five notebooks and the concepts they cover.

## 2026-04-18
- Scaffolded `Rate Limiting And Throttling` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
