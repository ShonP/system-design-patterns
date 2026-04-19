# Rate Limiting And Throttling

> Part of `04-patterns/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Overview

Controlling request rates at the edge and between services.

## Concepts covered

- Why rate limiting (bad case: no limiter, noisy-neighbor DoS)
- Rate limiting vs throttling vs quotas vs backpressure
- HTTP `429 Too Many Requests` + `Retry-After` + `X-RateLimit-*` headers
- Token bucket (burst-tolerant) — AWS / Stripe / NGINX
- Leaky bucket (paced output) — traffic shaping
- Fixed vs sliding-window counter — the boundary-burst bug
- Hybrid sliding-window counter (O(1)) — Cloudflare / Kong
- Distributed limiters with a shared store (Redis-style)
- Client-side exponential backoff **with full jitter** (AWS pattern)
- Concurrency limiting (in-flight cap with a semaphore) vs rate limiting
- Cost/weight-based limits, fail-open vs fail-closed, picking the limit key (IPv4 NAT, IPv6 `/64`, `X-Forwarded-For`)

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
- [`notebooks/02_leaky_bucket.ipynb`](./notebooks/02_leaky_bucket.ipynb) — paces traffic to a constant tempo; side-by-side plot vs token bucket.
- [`notebooks/03_sliding_window.ipynb`](./notebooks/03_sliding_window.ipynb) — fixed-window boundary burst vs sliding-window log vs O(1) hybrid counter.
- [`notebooks/04_distributed_and_backoff.ipynb`](./notebooks/04_distributed_and_backoff.ipynb) — Redis-style shared counter across servers + client-side exponential backoff with full jitter.
- [`notebooks/05_concurrency_and_practice.ipynb`](./notebooks/05_concurrency_and_practice.ipynb) — in-flight concurrency caps (semaphore), cost-based limits, where to enforce (edge / gateway / service), fail-open vs fail-closed, choosing the limit key.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
