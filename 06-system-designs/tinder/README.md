# Design a Dating App Like Tinder

📖 **Source**: [Hello Interview – Tinder System Design](https://www.hellointerview.com/learn/system-design/problem-breakdowns/tinder)

## Overview

Tinder connects people by showing a stack of nearby profiles to swipe through. Behind the simple swipe gesture is a system that must handle geolocation-based matching across millions of users, process billions of swipes per day with strong consistency for match detection, and deliver real-time notifications the instant a mutual match occurs.

This lab lets you build and experiment with the core pieces yourself using real tools: **PostGIS** for geospatial queries, **Redis** for atomic swipe matching and real-time pub/sub notifications, and **PostgreSQL** for durable profile and swipe storage.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Geolocation-Based Matching | PostGIS spatial queries, finding nearby users, filtering by preferences |
| 2 | Swipe and Match System | Atomic swipe recording with Redis Lua scripts, match detection, consistency |
| 3 | Real-Time Notifications | Redis Pub/Sub for instant match notifications, notification delivery patterns |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL and coordinates (latitude/longitude)

## Quick Start

```bash
# Navigate to the lab directory
cd 06-system-designs/tinder

# Start PostgreSQL (with PostGIS) + Redis + Visualization Tools
docker compose up -d

# Install dependencies
uv sync

# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `tinder_demo`
- **Use for**: Explore the schema, run spatial queries, inspect swipes and matches

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch swipe keys, see Pub/Sub channels, monitor atomic operations

## Key Concepts Covered

### Geolocation-Based Matching
- **PostGIS** — PostgreSQL extension for geographic data types and spatial queries
- **SRID 4326** — The coordinate reference system for GPS (latitude/longitude on Earth)
- **ST_DWithin / ST_Distance** — PostGIS functions for proximity searches
- **Spatial indexes (GIST)** — R-tree indexes that make location queries fast

### Swipe & Match Consistency
- **Atomic operations** — Redis Lua scripts to record a swipe and check for match in one step
- **User-pair partitioning** — Sorting user IDs so both directions of a swipe hit the same key
- **Race condition prevention** — Why naive check-then-write fails with concurrent swipes
- **Exactly-once match detection** — With simultaneous mutual swipes, precisely one side reports the match: zero loses it, two double-notify
- **Idempotent swipes** — A retried request must re-record the swipe without firing a second match event
- **Hybrid storage** — Redis for real-time match detection, PostgreSQL for durable history

### Real-Time Notifications
- **Redis Pub/Sub** — Instant message delivery to connected clients
- **Push notification patterns** — APNS/FCM for offline users
- **Notification lifecycle** — Creating, delivering, and marking notifications as read

## Architecture Overview

```
┌──────────┐     ┌──────────┐
│  User A  │     │  User B  │
│  Client  │     │  Client  │
└────┬─────┘     └────┬─────┘
     │                │
     ▼                ▼
┌─────────────────────────────┐
│        API Gateway          │
└──────┬──────────────┬───────┘
       │              │
       ▼              ▼
┌────────────┐  ┌──────────────┐
│  Profile   │  │    Swipe     │
│  Service   │  │   Service    │
└──────┬─────┘  └──┬───────┬───┘
       │           │       │
       ▼           ▼       ▼
┌────────────┐  ┌──────┐  ┌─────────────┐
│ PostgreSQL │  │Redis │  │ Notification│
│ + PostGIS  │  │(Lua) │  │  Service    │
└────────────┘  └──────┘  └──────┬──────┘
                                 │
                          ┌──────┴──────┐
                          │ Redis       │
                          │ Pub/Sub     │
                          └─────────────┘
```

## Real-World Scale

| Metric | Value |
|--------|-------|
| Daily active users | ~20 million |
| Swipes per day | ~2 billion (100 swipes/user avg) |
| Feed load latency target | < 300 ms |
| Match detection | Immediate (strong consistency) |
| Location freshness | Updated on app open |

## What This Lab Does *Not* Model

Worth knowing before you quote any of this in an interview:

- **The "already seen" set lives in PostgreSQL.** The feed query uses `NOT EXISTS` against
  the `swipes` table. At 2B swipes/day that does not survive contact with production, which
  keeps a per-user seen-set in Redis or a probabilistic filter. A Bloom filter is the classic
  choice and its false positives are not free: a false positive means a profile is silently
  never shown to that user again, and you cannot tell which one. Usually an acceptable trade —
  but a trade.
- **No feed prefetch.** We query on demand; real systems pre-compute the next batch in the
  background while you swipe the current one.
- **Locations never change.** No cache invalidation when a user crosses town.
- **Single Redis, single Postgres.** No sharding, no replication lag, no failover. The
  user-pair key pattern is what makes sharding possible later, but we never shard here.
- **Redis is the match-detection source of truth for the duration of a request.** If Redis
  loses the hash, a user re-swipes. Notebook 2 discusses when that is not good enough.

## License

Educational content — feel free to use and modify for learning purposes.
