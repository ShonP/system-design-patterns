# Rate Limiter System Design

A hands-on system design exercise where we build a rate limiter step by step — exploring algorithms, distributed challenges, and scaling to 1M requests/second.

---

## Understanding the Problem

A rate limiter controls how many requests a client can make within a specific timeframe. It acts like a traffic controller for your API — allowing, for example, 100 requests per minute from a user, then rejecting excess requests with an HTTP 429 "Too Many Requests" response.

**Why rate limit?**
- Prevent abuse and denial-of-service attacks
- Protect servers from being overwhelmed by traffic bursts
- Ensure fair usage across all users
- Control costs for expensive API operations

---

## Functional Requirements

### In Scope

| # | Requirement |
|---|-------------|
| 1 | Identify clients by **user ID, IP address, or API key** to apply appropriate limits |
| 2 | Limit HTTP requests based on **configurable rules** (e.g., 100 requests/min/user) |
| 3 | Reject excess requests with **HTTP 429** and include helpful headers (`X-RateLimit-Remaining`, `X-RateLimit-Reset`) |

### Out of Scope

- Complex querying or analytics on rate limit data
- Long-term persistence of rate limiting data

---

## Non-Functional Requirements

**Scale assumption:** 1 million requests/second across 100 million daily active users.

### In Scope

| # | Requirement | Details |
|---|-------------|---------|
| 1 | **Low latency** | < 10ms overhead per request check |
| 2 | **High availability** | Eventual consistency is OK — slight delays in enforcement across nodes are acceptable |
| 3 | **Scale** | 1M requests/second, 100M DAU |

### Out of Scope

- Strong consistency guarantees across all nodes

---

## Core Entities

| Entity | Description |
|--------|-------------|
| **Rule** | Rate limiting policy: requests per time window, which clients it applies to, which endpoints. E.g., "authenticated users get 1000 requests/hour" |
| **Client** | The entity being rate limited — user ID, IP address, API key, or combination. Has associated usage state. |
| **Request** | Incoming API request with context: client identity, endpoint, timestamp. Evaluated against applicable rules. |

---

## System Interface

```
isRequestAllowed(clientId, ruleId) -> {
  passes: boolean,
  remaining: number,
  resetTime: timestamp
}
```

Returns whether the request is allowed and provides info for response headers (`X-RateLimit-Remaining`, `X-RateLimit-Reset`).

---

## High-Level Design

### 1. Where Does the Rate Limiter Live?

Three placement options, each with different trade-offs:

| # | Placement | How It Works | Pros | Cons |
|---|-----------|-------------|------|------|
| ❌ | **In-process** | Each app server checks local counters | Zero latency, no dependencies | No global view — 5 servers × 100 limit = 500 actual. Only works for single-server setups. |
| 🟡 | **Dedicated service** | App servers call a rate limit microservice per request | Full app context, global state, flexible rules | Extra network hop on every request, another service to maintain, new failure mode |
| ✅ | **API Gateway** | Rate limiter at the edge, before requests reach app servers | Blocked requests never reach app servers, centralized, simple | Limited to HTTP request context (headers, IP, URL). No deep business logic. |

**We choose: API Gateway placement.** Most common in production. Centralized control, no extra hops.

```
┌────────┐       ┌──────────────────────────┐       ┌───────────────┐
│        │──────>│  API Gateway             │──────>│  App Servers  │
│ Client │       │  ┌────────────────────┐  │       │  (only see    │
│        │<──429─│  │  Rate Limiter      │  │       │   allowed     │
└────────┘       │  │  check(clientId,   │  │       │   requests)   │
                 │  │        rule)       │  │       └───────────────┘
                 │  └────────────────────┘  │
                 └──────────────────────────┘
```

### 2. How Do We Identify Clients?

Since we're in the API Gateway, we only have HTTP request context. Three options:

| Strategy | Source | Best For | Watch Out |
|----------|--------|----------|-----------|
| **User ID** | `Authorization` header (JWT) | Authenticated APIs | Requires auth — doesn't work for public endpoints |
| **IP Address** | `X-Forwarded-For` header | Public APIs, unauthenticated | NAT / corporate firewalls — thousands of users behind one IP |
| **API Key** | `X-API-Key` header | Developer APIs | Key sharing, key theft |

In practice, **layer multiple rules** and enforce the most restrictive:

```
Request arrives → extract clientId (user, IP, API key)
  → Check per-user limit:     "Alice: 1000 req/hour"          → ✅ 50/1000
  → Check per-IP limit:       "1.2.3.4: 100 req/min"          → ❌ 101/100 → HTTP 429!
  → Check endpoint limit:     "GET /search: 10 req/min/user"   → (not checked, already rejected)
```

### 3. Rate Limiting Algorithms

Four main algorithms, each with different trade-offs:

| Algorithm | Idea | Memory | Accuracy | Burst Handling |
|-----------|------|--------|----------|----------------|
| **Fixed Window Counter** | Count requests per time bucket, reset at window boundary | ✅ 1 counter/client | ❌ Boundary spike (2× limit) | ❌ No burst control |
| **Sliding Window Log** | Store every request timestamp, remove expired ones | ❌ 1 timestamp/request | ✅ Perfect | ✅ Precise |
| **Sliding Window Counter** | Weighted average of current + previous window counters | ✅ 2 counters/client | 🟡 Approximation | 🟡 Approximate |
| **Token Bucket** ✅ | Bucket fills at steady rate, each request takes a token | ✅ 2 values/client | ✅ Precise | ✅ Natural burst support |

**We choose: Token Bucket.** Best balance of simplicity, memory, and real-world burst handling. Used by Stripe, AWS, and others.

**How Token Bucket works with Redis:**

```
┌────────────┐      ┌────────────────┐       ┌────────────┐
│ Gateway A  │─────>│                │       │            │
│ Gateway B  │─────>│     Redis      │       │ Lua script │
│ Gateway C  │─────>│                │<──────│ (atomic    │
└────────────┘      │  alice:bucket  │       │  read +    │
                    │  {tokens: 47,  │       │  calc +    │
                    │   last_refill} │       │  update)   │
                    └────────────────┘       └────────────┘
```

1. Request arrives at any gateway for user Alice
2. Gateway sends Lua script to Redis (atomic — no race conditions)
3. Script reads `tokens` + `last_refill`, calculates refill, checks if token available
4. If yes → decrement, allow. If no → reject with 429.
5. `EXPIRE` auto-cleans inactive buckets after 1 hour

**Why Lua scripting?** Without it, read + calculate + update are separate operations → race condition when two gateways check the same bucket simultaneously. Lua scripts execute atomically in Redis.

### 4. HTTP 429 Response & Headers

When a request is rejected, return a helpful response:

```
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1640995200
Retry-After: 60

{"error": "Rate limit exceeded", "message": "Try again in 60 seconds."}
```

| Header | Purpose |
|--------|---------|
| `X-RateLimit-Limit` | The limit ceiling (e.g., 100 requests/min) |
| `X-RateLimit-Remaining` | How many requests are left in this window |
| `X-RateLimit-Reset` | Unix timestamp when the limit resets |
| `Retry-After` | Seconds to wait before retrying |

**Drop vs queue?** We drop (fail fast). Queuing creates memory pressure, unpredictable latency, and retry storms. For interactive APIs, immediate 429 is almost always the right answer.

---

## Deep Dives

### Deep Dive 1: Scaling to 1M Requests/Second (Redis Sharding)

**Problem:** A single Redis instance handles ~100K ops/sec. Our Token Bucket requires multiple ops per check. At 1M req/s, one Redis is a bottleneck.

**Solution — Shard Redis by client ID using consistent hashing:**

```
┌────────────┐                    ┌──────────────┐
│ Gateway A  │─── hash(userId) ──>│ Redis Shard 1│  clients a-f
│ Gateway B  │─── hash(userId) ──>│ Redis Shard 2│  clients g-m
│ Gateway C  │─── hash(userId) ──>│ Redis Shard 3│  clients n-s
│ Gateway D  │─── hash(userId) ──>│ Redis Shard 4│  clients t-z
└────────────┘                    └──────────────┘

Each shard handles ~100K ops/sec → 10 shards = 1M ops/sec
```

**Key requirement:** All requests from client X must hit the same shard. Otherwise, rate limit state gets split and becomes useless.

**In production:** Use **Redis Cluster** — auto-shards keys across 16,384 hash slots distributed across nodes. No custom consistent hashing needed.

### Deep Dive 2: High Availability & Fault Tolerance

**Problem:** If a Redis shard dies, all users on that shard lose rate limiting. What do we do?

**Failure mode decision:**

| | Fail Closed (reject all) | Fail Open (allow all) |
|-|--------------------------|----------------------|
| **Behavior** | Return 503/429 for all requests when Redis unreachable | Skip rate limiting, forward all requests to backend |
| **Risk** | API goes offline even when backend is healthy | Lose rate limit protection → backend overwhelm |
| **Best for** | High-security, financial systems, social media during viral events | Low-risk APIs where uptime > protection |

**We choose: Fail closed.** Rate limiter failures often coincide with traffic spikes — failing open during a viral event would flood the backend and cause cascading collapse. Brief rejected requests < total platform failure.

**Prevention — Redis master-replica failover:**

```
┌──────────────┐     replication     ┌──────────────┐
│ Redis Master │ ──────────────────> │ Redis Replica│
│  (active)    │                     │  (standby)   │
└──────┬───────┘                     └──────┬───────┘
       │                                     │
       │  master fails                       │  auto-promoted
       v                                     v
   ❌ down                              ✅ new master
```

Redis Cluster has built-in failover: detects master failure, promotes replica automatically. Trade-off: increased infra cost + brief replication lag during promotion.

### Deep Dive 3: Minimizing Latency Overhead

**Problem:** Every rate limit check = network round trip to Redis. At 1M req/s, even a few ms per check matters.

**Key optimizations:**

| Optimization | Impact | How |
|-------------|--------|-----|
| **Connection pooling** | Eliminates 20-50ms TCP handshake per request | Reuse persistent connections to Redis. Most clients do this automatically — tune pool size. |
| **Geographic distribution** | Biggest win — ms → μs | Deploy Redis clusters in each region close to users. Tokyo user → Tokyo Redis, not Virginia Redis. |
| **Lua scripting** | Reduces round trips from 2+ to 1 | Already doing this — entire Token Bucket check is one atomic Lua call. |

**Advanced (mention if asked):**
- **Local caching** — cache rate limit state in gateway memory. Risky: stale cache → incorrect decisions.
- **Redis pipelining** — batch multiple ops in one network call. Useful for multi-rule checks.
- **Request batching** — group concurrent requests from same user. Adds complexity, rarely needed.

> In an interview: connection pooling + geo-distribution + Lua scripts cover 95% of latency wins. Only mention the rest if explicitly asked.

### Deep Dive 4: Dynamic Rule Configuration

**Problem:** Rules need to change without code deploys — product launches, premium tiers, attack response.

| | 🟡 Poll-based (Good) | 🟢 Push-based (Great) |
|-|----------------------|----------------------|
| **How** | Gateways poll a config DB every 30s, cache locally | ZooKeeper / Redis Pub/Sub pushes changes instantly to all gateways |
| **Propagation delay** | Up to 30s (polling interval) | Seconds |
| **Complexity** | Simple — just a DB table + polling loop | Higher — connection management, partial failure handling |
| **Best for** | Most systems — delay is acceptable | Security-critical systems needing instant response |

```
Poll-based:
  Admin UI ──> Config DB ──(poll every 30s)──> Gateway A, B, C update rules

Push-based:
  Admin UI ──> ZooKeeper ──(instant push)──> Gateway A, B, C update rules
```

For most rate limiters, **poll-based is sufficient**. 30 seconds of stale rules is acceptable. Push-based adds complexity that's only justified for high-security or incident-response scenarios.

---

## Labs

Hands-on notebooks that walk through each design decision with working code.

| # | Notebook | Topic |
|---|----------|-------|
| 1 | `01_placement_and_identification.ipynb` | Rate limiter placement, client identification, layered rules |
| 2 | `02_algorithms.ipynb` | All 4 algorithms implemented + compared, Token Bucket with Redis Lua |
| 3 | `03_http_429_response.ipynb` | HTTP 429 responses, rate limit headers, complete middleware |
| 4 | `04_scaling.ipynb` | Deep dive — Redis sharding, consistent hashing, simulating 1M req/s |
| 5 | `05_high_availability.ipynb` | Deep dive — fail open vs closed, Redis failover, circuit breaker |
