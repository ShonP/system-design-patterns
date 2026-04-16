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
cd system-designs/tinder

# Start PostgreSQL (with PostGIS) + Redis + Visualization Tools
docker-compose up -d

# Install dependencies
uv sync

# Register Jupyter kernel
uv run python -m ipykernel install --user --name=tinder --display-name="Tinder Lab (Python)"

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

## License

Educational content — feel free to use and modify for learning purposes.
