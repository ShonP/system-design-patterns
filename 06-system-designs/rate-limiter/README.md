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
cd system-designs/rate-limiter

# Start Redis + Flask API + Visualization Tools
docker-compose up -d

# Install dependencies
uv sync

# Register Jupyter kernel
uv run python -m ipykernel install --user --name=rate-limiter --display-name="Rate Limiter (Python)"

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
- **Race Conditions** — two gateways reading the same bucket simultaneously
- **Redis Lua Scripts** — atomic read-calculate-update in one operation
- **Sharding** — consistent hashing to scale beyond one Redis instance
- **Fail Open vs Fail Closed** — what happens when Redis goes down

### HTTP 429 Response
- `X-RateLimit-Limit` — the rate limit ceiling
- `X-RateLimit-Remaining` — requests left in current window
- `X-RateLimit-Reset` — when the limit resets (Unix timestamp)
- `Retry-After` — seconds to wait before retrying

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
