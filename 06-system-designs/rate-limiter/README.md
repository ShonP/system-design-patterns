# Rate Limiter System Design

📖 **Source**: [Hello Interview – Design a Distributed Rate Limiter](https://www.hellointerview.com/learn/system-design/problem-breakdowns/distributed-rate-limiter)

## Overview

A rate limiter controls how many requests a client can make within a specific timeframe. It acts like a traffic controller for your API — allowing, for example, 100 requests per minute from a user, then rejecting excess requests with an HTTP 429 "Too Many Requests" response.

**Why rate limit?**
- Prevent abuse and denial-of-service attacks
- Protect servers from being overwhelmed by traffic bursts
- Ensure fair usage across all users
- Control costs for expensive API operations

This lab walks you through the core algorithms, distributed challenges with Redis, and how to integrate rate limiting into an API gateway — all with runnable code.

## Requirements

### Functional

| # | Requirement |
|---|-------------|
| 1 | Reject requests from a client that exceeds a configured rate |
| 2 | Return HTTP **429** with `Retry-After` so clients know when to come back |
| 3 | Support multiple rules — per endpoint, per client tier |
| 4 | Identify clients by API key, user id, or IP (in that priority) |
| 5 | Limits are enforced **globally**, not per gateway instance |

### Non-Functional

| # | Requirement | Target |
|---|-------------|--------|
| 1 | **Low latency** | the check must be a rounding error on the request it guards — < 2 ms p99 |
| 2 | **Availability** | the limiter must not be able to take the API down (see fail-open below) |
| 3 | **Accuracy** | no client should get materially more than its limit; a small overshoot at window edges is acceptable, 2× is not |
| 4 | **Scale** | 1M requests/sec across the fleet, 100M distinct clients |

### Explicitly out of scope

Authentication, quota billing, per-request cost weighting (a "search" costing 5 tokens
instead of 1), and DDoS mitigation at L3/L4 — a rate limiter operating at L7 has already
paid for the TCP handshake by the time it says no.

---

## Capacity Estimate

Assumptions: **1M requests/sec** at peak, **100M** clients active in any hour, and
**3 rules** per client (default / search / premium).

**Redis operations**

```
Every request = exactly 1 EVALSHA (the whole token bucket is one script).
  → 1M Redis ops/sec

Plan at 100K ops/sec per Redis instance. (A single instance can do several
times that on simple GETs, but EVALSHA is heavier and you never want to run
a rate limiter at its ceiling — that is precisely when traffic spikes.)

  1,000,000 / 100,000 = 10 shards, round up to 16 for headroom and hot keys
```

**Memory**

```
One bucket = a Redis hash with 2 fields (tokens, last_refill)
  key string        ~40 B   "ratelimit:default:apikey:a1b2c3..."
  hash + expiry     ~110 B  (small hashes use the compact listpack encoding)
  ------------------------------
  ~150 B per bucket

100M clients x 3 rules x 150 B = 45 GB
  spread over 16 shards        = ~2.8 GB per shard
```

That fits comfortably on commodity nodes — and it only stays that size because every
key carries an `EXPIRE`. Drop the TTL and this grows without bound, because the set of
clients that ever existed is much larger than the set active right now.

**Bandwidth**

```
~100 B request + ~100 B response per check
1M/sec x 200 B = 200 MB/sec across the whole fleet
```

Negligible — a rate limiter is a latency and ops-count problem, never a bandwidth one.

**The number that actually constrains the design**

```
1M req/sec x 0.5 ms Redis round-trip = 500 seconds of latency incurred per second
  → 500 concurrent in-flight checks at any instant
```

Which is fine with async I/O or a connection pool, but it is the reason the check has
to be **one** round-trip. A read-then-write design would double both the ops count and
the latency — and, as Lab 3 demonstrates, it would not even be correct.

---

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Token Bucket + Leaky Bucket | Token bucket (burst-friendly), Leaky bucket (smoothing), when to pick which |
| 2 | Sliding Window Counter + Log | Fixed window boundary problem, sliding window counter, sliding window log (exact) |
| 3 | Distributed Rate Limiting with Redis | Why local counters fail, Redis + Lua scripts for atomic rate limiting, race conditions |
| 4 | Rate Limiting at API Gateway Level | Flask middleware, end-to-end rate-limited API, tiered limits, HTTP 429 + client retry with exponential backoff |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of HTTP APIs

## Quick Start

```bash
# Navigate to the lab directory
cd 06-system-designs/rate-limiter

# Start Redis + Flask API + Visualization Tools
docker compose up -d

# Install dependencies
uv sync

# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5541
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch rate limit keys appear/expire, monitor token counts, see Lua script execution

## Key Concepts Covered

### Rate Limiting Algorithms
- **Token Bucket** — bucket fills at steady rate, each request takes a token *(our primary choice)*
- **Fixed Window Counter** — count per time bucket, reset at boundary *(simple but has edge cases)*
- **Sliding Window Counter** — weighted average of current + previous window *(good approximation)*
- **Sliding Window Log** — store every timestamp *(perfect accuracy, high memory)*

### Where to Place the Rate Limiter
- **In-Process** — local memory, fast but no global view
- **Dedicated Service** — full context but extra network hop
- **API Gateway** — most common, centralized control *(our choice)*

### Distributed Challenges
- **Race Conditions** — two gateways reading the same bucket simultaneously. Lab 3 races
  the naive implementation with 30 threads and measures the overshoot (consistently
  12–18 allowed against a limit of 10), then fixes it atomically.
- **Redis Lua Scripts** — atomic read-calculate-update in one operation
- **Clock skew** — the subtler bug that survives the atomicity fix. If each gateway
  passes its own `now` into the script, a gateway with a fast clock refills every
  bucket it touches. Lab 3 demonstrates this and fixes it with `redis.call('TIME')`.
- **Sharding** — consistent hashing to scale beyond one Redis instance
- **Fail Open vs Fail Closed** — the server defaults to **fail open**
  (`RATE_LIMIT_FAIL_MODE`) and marks degraded responses with `X-RateLimit-Degraded`.
  A rate limiter that can take the whole API down has failed at its job. Fail closed
  only when the work behind it costs more than the outage.

### HTTP 429 Response
- `X-RateLimit-Limit` — the rate limit ceiling
- `X-RateLimit-Remaining` — requests left in current window
- `X-RateLimit-Reset` — Unix timestamp when the bucket is **full** again
- `Retry-After` — seconds until **one** token is available. Not the time to a full
  bucket: sending `max_tokens / refill_rate` is a common bug that makes clients idle
  ~10× longer than necessary. Lab 4 asserts the value is neither too short (obeying it
  would still 429) nor needlessly long.

## Architecture

```
┌────────┐       ┌──────────────────────────┐       ┌───────────────┐
│        │──────>│  API Gateway (Flask)     │──────>│  App Logic    │
│ Client │       │  ┌────────────────────┐  │       │  (only sees   │
│        │<──429─│  │  Rate Limiter      │  │       │   allowed     │
└────────┘       │  │  (Redis-backed)    │  │       │   requests)   │
                 │  └────────┬───────────┘  │       └───────────────┘
                 └───────────┼──────────────┘
                             │
                      ┌──────▼──────┐
                      │    Redis    │
                      │  (tokens,   │
                      │  timestamps)│
                      └─────────────┘
```

## License

Educational content — feel free to use and modify for learning purposes.
