# Scaling Reads Pattern

📖 **Scaling Reads** addresses the challenge of serving high-volume read requests when your application grows from hundreds to millions of users. While writes create data, reads consume it - and read traffic often grows faster than write traffic.

## Overview

This pattern covers architectural strategies to handle massive read loads without crushing your primary database. You'll learn the natural progression from simple optimization to complex distributed caching.

## The Problem

Consider an Instagram feed. When you open the app, you're immediately hit with dozens of photos, each requiring multiple database queries to fetch image metadata, user information, like counts, and comment previews. That's potentially 100+ read operations just to load your feed. Meanwhile, you might only post one photo per day - a single write operation.

```
Read/Write Ratios in Real Systems:
────────────────────────────────────────────────────────────────────
System              Reads           Writes          Ratio
────────────────────────────────────────────────────────────────────
Twitter             Billions/day    ~500M tweets    ~100:1
Amazon Products     Billions/day    Millions        ~1000:1
YouTube             Billions views  Millions upload ~10000:1
URL Shortener       Billions        Millions        ~1000:1
────────────────────────────────────────────────────────────────────
```

As reads increase, your database will struggle under the load. This isn't a software problem you can debug your way out of - it's physics.

## Notebooks in This Series

### Part 1: Understanding the Problem
- Read vs write patterns
- Measuring database performance
- Identifying bottlenecks

### Part 2: Database Optimization
- Indexing strategies (B-tree, Hash, Composite)
- Covering indexes (`INCLUDE`) and partial indexes
- Using EXPLAIN to analyze queries
- Query optimization techniques
- Connection pooling (in-process + PgBouncer)

### Part 3: Denormalization
- Normalized vs denormalized schemas
- Materialized views
- Pre-computed aggregations

### Part 4: Read Replicas
- Leader-follower replication
- Synchronous vs asynchronous replication
- Handling replication lag

### Part 5: Application Caching
- Redis as a cache layer
- TTL strategies
- Cache invalidation approaches

### Part 6: Advanced Cache Patterns
- Cache stampede prevention (distributed lock + probabilistic early refresh)
- Hot key problem (key fanout)
- Request coalescing / single-flight
- Cache versioning

## Prerequisites

- Python 3.10+
- [uv](https://docs.astral.sh/uv/) (fast Python package manager)
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the pattern directory
cd 04-patterns/scaling-reads

# Start PostgreSQL + Redis + Visualization Tools
docker compose up -d

# Install dependencies
uv sync

# Open a notebook in VS Code and select the `.venv` kernel from the top-right kernel picker.
# If the kernel doesn't appear, reload the VS Code window (Cmd+Shift+P → "Developer: Reload Window").
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System: `PostgreSQL`, Server: `postgres`, Username: `demo`, Password: `demo`, Database: `scaling_demo`
- **Use for**: Watch query execution, see EXPLAIN plans, observe index usage

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host: `redis`, Port: `6379`
- **Use for**: Watch cache hits/misses, TTL expiration, key patterns

## Real-World Applications

| Application | Technique | Why |
|-------------|-----------|-----|
| Bitly | Aggressive caching | One URL shortened, millions of reads |
| Ticketmaster | CDN + Cache | Event pages hammered on sale |
| Instagram | Read replicas + Cache | Feed generation is read-intensive |
| YouTube | CDN + Materialized views | Video metadata queried billions of times |
| Amazon | Denormalization + Cache | Product pages viewed constantly |

## Decision Flowchart

```
                    ┌─────────────────────────────┐
                    │ Are reads slow or DB        │
                    │ under heavy load?           │
                    └─────────────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
                  Yes                       No
                    │                       │
                    ▼                       ▼
            ┌───────────────┐      ┌───────────────┐
            │ Check indexes │      │ You're fine!  │
            │ first         │      │               │
            └───────────────┘      └───────────────┘
                    │
                    ▼ Still slow?
            ┌───────────────┐
            │ Denormalize   │
            │ hot queries   │
            └───────────────┘
                    │
                    ▼ Still slow?
            ┌───────────────┐
            │ Add caching   │
            │ (Redis)       │
            └───────────────┘
                    │
                    ▼ Still slow?
            ┌───────────────┐
            │ Read replicas │
            │ or sharding   │
            └───────────────┘
```

## Key Takeaways

1. **Start simple** - Proper indexing solves most read problems
2. **Measure first** - Use EXPLAIN before optimizing blindly
3. **Cache strategically** - Cache what's read often and changes rarely
4. **Understand trade-offs** - Caching adds complexity and staleness
5. **Know your ratios** - High read/write ratio = cache aggressively

## License

Educational content - feel free to use and modify for learning purposes.
