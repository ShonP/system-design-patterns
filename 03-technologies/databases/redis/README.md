# 🔴 Redis Deep Dive

> **Learning Source**: [Hello Interview — Redis Deep Dive](https://www.hellointerview.com/learn/system-design/deep-dives/redis)

## Overview

Redis is an **in-memory, single-threaded data structure store** written in C. It is one of the most versatile tools in system design — rather than learning many technologies superficially, Redis lets you go deep with one technology that can serve as a **cache, message broker, leaderboard, rate limiter, distributed lock**, and much more.

In this lab you'll explore Redis hands-on — from fundamental data structures to pub/sub messaging, caching strategies, and high-availability configurations with Sentinel and replication.

### Why Redis?

- **Versatility** — one tool covers caching, messaging, counting, ranking, geo-queries, and more
- **Simplicity** — features map directly to familiar data structures (hashes, sets, sorted sets, streams)
- **Performance** — handles ~100k writes/sec; read latency often in the microsecond range

## Prerequisites

- Python 3.10+
- Docker and Docker Compose
- Basic understanding of key-value stores

## Quick Start

```bash
# 1. Navigate to the lab directory
cd 03-technologies/databases/redis

# 2. Start all services (Redis standalone, master+replicas, Sentinel cluster, RedisInsight)
docker compose up -d

# 3. Install dependencies into a per-lab .venv (managed by uv)
uv sync

# 4. Open the notebooks in VS Code (or `uv run jupyter lab`)
#    In VS Code: pick the .venv kernel from the kernel picker (top-right of the notebook).
#    If the kernel doesn't appear, reload: Cmd+Shift+P → "Reload Window".
```

> 🔁 **Re-running notebook 4?** It deliberately triggers a Sentinel failover.
> If a previous run left the topology with a different node as master,
> reset it before re-running:
>
> ```bash
> docker compose restart redis-master redis-replica-1 redis-replica-2 \
>   sentinel-1 sentinel-2 sentinel-3
> ```

## 🔍 Visualization Tools

### RedisInsight (Redis GUI)

- **URL**: [http://localhost:5540](http://localhost:5540)
- Connect to **standalone Redis** at `redis://localhost:6379`
- Connect to **Redis master** at `redis://localhost:6380`
- Connect to **replicas** at `redis://localhost:6381` and `redis://localhost:6382`

RedisInsight lets you browse keys, run commands, and monitor Redis in real time — great for following along with the notebooks.

## 🏗️ Architecture

This lab runs the following Docker services:

```
┌──────────────────────────────────────────────────────────┐
│                     Docker Network                        │
│                                                           │
│  ┌────────────┐                                           │
│  │   Redis     │  ← Used by notebooks 1, 2, 3, 5          │
│  │ Standalone  │                                          │
│  │   :6379     │                                          │
│  └────────────┘                                           │
│                                                           │
│  ┌────────────┐    ┌────────────┐    ┌────────────┐      │
│  │   Redis     │───▶│  Replica 1 │    │  Replica 2 │      │
│  │   Master    │    │   :6381    │    │   :6382    │      │
│  │   :6380     │───▶└────────────┘    └────────────┘      │
│  └──────┬─────┘              ▲               ▲            │
│         │                    │               │            │
│  ┌──────┴────────────────────┴───────────────┴──┐        │
│  │          Sentinel Cluster (quorum=2)          │        │
│  │  Sentinel 1 :26379  │  2 :26380  │  3 :26381 │        │
│  └───────────────────────────────────────────────┘        │
│                                                           │
│  ┌────────────────┐                                       │
│  │  RedisInsight   │  http://localhost:5540                │
│  └────────────────┘                                       │
└──────────────────────────────────────────────────────────┘
```

## 📓 Notebooks

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | [Redis Data Structures](notebooks/01_redis_data_structures.ipynb) | Strings, hashes, lists, sets, sorted sets, streams, geospatial indexes |
| 2 | [Pub/Sub & Streams](notebooks/02_pub_sub_patterns.ipynb) | Pub/sub messaging, Redis Streams, consumer groups, work queues |
| 3 | [Cache vs Primary Store](notebooks/03_redis_as_cache_vs_primary.ipynb) | Cache-aside, write-through, TTL, distributed locks (safe + naive), rate limiting (fixed + sliding window), cache stampede |
| 4 | [Cluster & Replication](notebooks/04_redis_cluster_and_replication.ipynb) | Master-replica setup, Sentinel automatic failover, hash slots, hot-key mitigation |
| 5 | [Performance, Atomicity & Probabilistic Structures](notebooks/05_pipelines_transactions_persistence.ipynb) | Pipelines, MULTI/EXEC, WATCH, Lua scripting, RDB vs AOF, Bitmaps, HyperLogLog |
| 5 | [Performance, Atomicity & Probabilistic Structures](notebooks/05_pipelines_transactions_persistence.ipynb) | Pipelines, MULTI/EXEC + WATCH, Lua scripts, RDB vs AOF, Bitmaps, HyperLogLog |

## 🌍 Real-World Applications

| System | Redis Use Case | Technique |
|--------|---------------|-----------|
| Twitter/X | Timeline caching | Sorted Sets + TTL |
| Instagram | Like counts | INCR + Sorted Sets |
| Uber | Driver proximity | Geospatial indexes |
| Slack | Real-time messaging | Pub/Sub + Streams |
| Stripe | Rate limiting | INCR + EXPIRE |
| Gaming platforms | Leaderboards | Sorted Sets |
| E-commerce | Session storage | Hashes + TTL |
| Netflix | Feature flags | Strings + Pub/Sub |

## 🧭 When to Use Redis

```
Need in-memory speed?
├── Yes
│   ├── Need durability?        → Redis with AOF / Redis Streams
│   ├── Need pub/sub?           → Redis Pub/Sub or Streams
│   ├── Need caching?           → Redis with TTL
│   ├── Need counting/ranking?  → Sorted Sets
│   ├── Need rate limiting?     → INCR + EXPIRE
│   ├── Need geo queries?       → Geospatial indexes
│   └── Need distributed locks? → INCR + TTL (or Redlock)
└── No
    └── Consider PostgreSQL, DynamoDB, etc.
```

## License

Educational content for learning system design concepts. Based on material from [Hello Interview](https://www.hellointerview.com).
