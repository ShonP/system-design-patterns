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
cd deep-dives/redis

# 2. Start all services (Redis standalone, Sentinel cluster, RedisInsight)
docker compose up -d

# 3. Create a Python virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# 4. Install dependencies
pip install -r requirements.txt

# 5. Register the Jupyter kernel
python -m ipykernel install --user --name=redis-deep-dive --display-name="Redis Deep Dive (Python)"

# 6. Open the notebooks in VS Code or Jupyter
# In VS Code: Select the "Redis Deep Dive (Python)" kernel from the kernel picker (top-right)
# If the kernel doesn't appear, reload the VS Code window (Cmd+Shift+P → "Reload Window")
```

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
│  │   Redis     │  ← Used by notebooks 1-3                 │
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
| 1 | [Redis Data Structures](notebooks/01_redis_data_structures.ipynb) | Strings, hashes, lists, sets, sorted sets, geospatial indexes |
| 2 | [Pub/Sub Patterns](notebooks/02_pubsub_patterns.ipynb) | Pub/sub messaging, Redis Streams, consumer groups, work queues |
| 3 | [Cache vs Primary Store](notebooks/03_cache_vs_primary_store.ipynb) | TTL, eviction, distributed locks, rate limiting, leaderboards |
| 4 | [Cluster & Replication](notebooks/04_cluster_and_replication.ipynb) | Master-replica setup, Sentinel HA, hash slots, hot key mitigation |

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
