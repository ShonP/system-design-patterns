# Rate Limiting And Throttling

> Part of `04-patterns/`. Six runnable notebooks, each showing the wrong version first and measuring exactly how it is wrong.

## Overview

Controlling request rates at the edge and between services.

## Concepts covered

- Why rate limiting (bad case: no limiter, noisy-neighbor DoS)
- Rate limiting vs throttling vs quotas vs backpressure
- HTTP `429 Too Many Requests` + `Retry-After` + `X-RateLimit-*` headers
- Token bucket (burst-tolerant) — AWS / Stripe / NGINX
- Leaky bucket (paced output) — traffic shaping
- **GCRA** (Generic Cell Rate Algorithm) — one-timestamp leaky bucket (Redis `redis-cell`, Shopify)
- Fixed vs sliding-window counter — the boundary-burst bug (demonstrated, not asserted)
- Hybrid sliding-window counter (O(1)) — Cloudflare / Kong, and its measured approximation error
- Distributed limiters: the read-then-write race on a shared counter, then the atomic fix (Lua-style)
- Client-side exponential backoff **with full jitter** (AWS pattern)
- Concurrency limiting (in-flight cap with a semaphore) vs rate limiting
- Cost/weight-based limits, fail-open vs fail-closed, picking the limit key (IPv4 NAT, IPv6 `/64`, `X-Forwarded-For`)
- Observability — the metrics to emit so you can actually see the limiter working

## Setup

```bash
cd 04-patterns/rate-limiting-and-throttling
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

Each notebook shows a **bad first try**, then a **better version**, with plots so you can *see* the difference.

- [`notebooks/00_intro.ipynb`](./notebooks/00_intro.ipynb) — why rate limit at all; vocabulary (RL vs throttling vs quotas); HTTP 429 / `Retry-After`.
- [`notebooks/01_token_bucket.ipynb`](./notebooks/01_token_bucket.ipynb) — burst-tolerant limiter used by AWS / Stripe / NGINX; per-key buckets.
- [`notebooks/02_leaky_bucket.ipynb`](./notebooks/02_leaky_bucket.ipynb) — the **shaper** (queues and paces, returns a service time) vs the **limiter** form (GCRA, yes/no); side-by-side plot of arrivals, limiter output and shaper output, plus the latency the shaper costs you.
- [`notebooks/03_sliding_window.ipynb`](./notebooks/03_sliding_window.ipynb) — a real clock-driven boundary attack (2× the limit through a fixed window), the exact sliding-window log, and the O(1) hybrid counter with its error measured in both directions.
- [`notebooks/04_distributed_and_backoff.ipynb`](./notebooks/04_distributed_and_backoff.ipynb) — per-server limits lie; a naive shared counter is racy (shown under 60-way concurrency); the atomic fix; real `429` responses with a computed `Retry-After`; and client-side exponential backoff with full jitter.
- [`notebooks/05_concurrency_and_practice.ipynb`](./notebooks/05_concurrency_and_practice.ipynb) — in-flight concurrency caps (semaphore), cost-based limits, where to enforce (edge / gateway / service), fail-open vs fail-closed, choosing the limit key.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
