# Caching

📖 **Source**: [Hello Interview – Caching for System Design Interviews](https://www.hellointerview.com/learn/system-design/core-concepts/caching)

## Overview

Caching is what you do when reading from the database is too slow or too expensive. It keeps frequently accessed data in fast memory so you can skip the database entirely for most reads.

Reading a user profile from Postgres takes ~50 ms. Reading from Redis takes ~1 ms. That's a **50× improvement**. Databases store data on disk; caches store data in memory, much closer to the CPU.

But caching also introduces new challenges: **invalidation**, **consistency**, and **failure handling**. This lab walks you through all of it with real, runnable code.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Introduction to Caching | Why cache, where to cache, measuring the problem |
| 2 | Cache-Aside Pattern | The most common caching pattern (lazy loading) |
| 3 | Write-Through & Write-Behind | Keeping the cache in sync with writes |
| 4 | Cache Invalidation & TTL | Eviction policies, TTL strategies, keeping data fresh |
| 5 | Cache Stampede & Hot Keys | Thundering herd prevention, hot key mitigation |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd core-concepts/caching

# Start PostgreSQL + Redis + Visualization Tools
docker-compose up -d

# Install dependencies
uv sync

# Register Jupyter kernel
uv run python -m ipykernel install --user --name=caching --display-name="Caching (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `caching_demo`
- **Use for**: Watch query execution, see table data, observe changes

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch cache keys appear/expire, monitor TTLs, see memory usage

## Key Concepts Covered

### Where to Cache
- **External Cache** (Redis/Memcached) — shared across app servers
- **CDN** — static media close to users
- **Client-Side** — browser/device local storage
- **In-Process** — local memory inside the app server

### Cache Architectures
- **Cache-Aside** — app checks cache, falls back to DB *(most common)*
- **Write-Through** — writes go to cache first, then synchronously to DB
- **Write-Behind** — writes go to cache, asynchronously flushed to DB
- **Read-Through** — cache itself fetches from DB on miss

### Eviction Policies
- **LRU** (Least Recently Used) — default in most systems
- **LFU** (Least Frequently Used) — good for consistently popular keys
- **TTL** (Time To Live) — must-have for freshness

### Common Problems
- **Cache Stampede** — many requests rebuild the same key at once
- **Cache Consistency** — cache and DB return different values
- **Hot Keys** — one key gets way more traffic than others

## Real-World Examples

| System | Why Caching Matters |
|--------|-------------------|
| Amazon | Product pages viewed millions of times, updated rarely |
| Twitter | Celebrity profiles hammered by millions of fans |
| YouTube | Video metadata queried billions of times |
| Bitly | One URL shortened, millions of redirect lookups |

## License

Educational content — feel free to use and modify for learning purposes.
