# Strava — GPS Activity Tracking & Social Fitness

📖 **Source**: [Hello Interview – Strava System Design](https://www.hellointerview.com/learn/system-design/problem-breakdowns/strava)

## Overview

Strava is a fitness tracking app where runners and cyclists record GPS-based activities, share them with friends, and compete on segment leaderboards. It's an excellent system design problem because it combines **geospatial data**, **social feeds**, and **real-time leaderboards** in one system.

This lab walks you through the core backend concepts with real, runnable code against Postgres (with PostGIS) and Redis.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | GPS Activity Tracking & Storage | Recording GPS points, Haversine distance, PostGIS spatial queries, pause/resume timing |
| 2 | Activity Feed & Social Features | Friends graph, fan-out feed queries, caching feeds in Redis |
| 3 | Route Matching & Segment Leaderboards | Matching GPS traces to segments, Redis Sorted Sets for leaderboards |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd system-designs/strava

# Start PostgreSQL (with PostGIS) + Redis + Visualization Tools
docker-compose up -d

# Install dependencies
uv sync

# Register Jupyter kernel
uv run python -m ipykernel install --user --name=strava --display-name="Strava (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `strava_demo`
- **Use for**: Explore activities, route points, segments, and friendships

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch leaderboard sorted sets, cached feeds, and TTLs

## Core Entities

```
┌──────────┐     ┌──────────────┐     ┌──────────────┐
│  Users   │────▶│  Activities  │────▶│ Route Points │
└──────────┘     └──────────────┘     │  (PostGIS)   │
     │                  │              └──────────────┘
     ▼                  ▼
┌──────────┐     ┌──────────────┐     ┌──────────────┐
│ Friends  │     │   Segments   │────▶│Segment Efforts│
└──────────┘     └──────────────┘     └──────────────┘
```

## Key Concepts Covered

### GPS & Geospatial
- Recording latitude/longitude at intervals
- **Haversine formula** for distance between two GPS points
- **PostGIS** for spatial indexing and geographic queries

### Activity Lifecycle
- Start → Pause → Resume → Complete state machine
- Accurate elapsed time via state log (excludes paused time)
- Offline-first: batch upload GPS data when activity completes

### Social Feed
- Bi-directional friendships
- Feed query: "show me my friends' recent activities"
- Caching feeds in Redis to avoid repeated expensive JOINs

### Segments & Leaderboards
- A **segment** is a famous stretch of road athletes race on
- **Route matching**: detect when a GPS trace crosses a segment
- **Redis Sorted Sets** for O(log N) leaderboard updates and queries
- Filtering leaderboards by city, country, and time range

## Scaling Considerations (from the Source)

| Challenge | Solution |
|-----------|----------|
| 10M concurrent activities | Track locally on device, upload on completion |
| ~36.5B activities/year | Shard by time, data tiering (hot/warm/cold) |
| Real-time friend tracking | Polling every 2–5 s (not WebSockets—updates are predictable) |
| Leaderboard at scale | Redis Sorted Sets with ZINCRBY, separate sets per country |

## License

Educational content — feel free to use and modify for learning purposes.
