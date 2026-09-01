# Strava — GPS Activity Tracking & Social Fitness

📖 **Source**: [Hello Interview – Strava System Design](https://www.hellointerview.com/learn/system-design/problem-breakdowns/strava)

## Overview

Strava is a fitness tracking app where runners and cyclists record GPS-based activities, share them with friends, and compete on segment leaderboards. It's an excellent system design problem because it combines **geospatial data**, **social feeds**, and **real-time leaderboards** in one system.

This lab walks you through the core backend concepts with real, runnable code against Postgres (with PostGIS) and Redis.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | GPS Activity Tracking & Storage | Recording GPS points, Haversine distance, PostGIS spatial queries, pause/resume timing, elevation gain without the fake mountain, polyline simplification |
| 2 | Activity Feed & Social Features | Friends graph, fan-out feed queries, keyset pagination, caching feeds in Redis |
| 3 | Route Matching & Segment Leaderboards | Matching GPS traces to segments (endpoints *and* path), Redis Sorted Sets for leaderboards |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd 06-system-designs/strava

# Start PostgreSQL (with PostGIS) + Redis + Visualization Tools
docker compose up -d

# If you have run this lab before, the seed data in db/init.sql only loads into a
# FRESH volume. Notebook 1 asserts that each activity's stored distance matches its
# own GPS track, so an old volume will fail loudly. Rebuild it with:
#   docker compose down -v && docker compose up -d

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
- **Elevation gain** — why summing raw altitude deltas reports a mountain that
  isn't there, and how smoothing + a hysteresis threshold fixes it without
  flattening the summit
- **Polyline simplification** (Douglas–Peucker) with the tolerance measured in
  metres, not degrees — one degree of longitude is not one degree of latitude

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
- **Route matching**: detect when a GPS trace crosses a segment — matching the two
  endpoints is not enough, because a detour between them matches too
- **Redis Sorted Sets** for O(log N) leaderboard updates and queries, with
  `ZADD ... lt=True` instead of a read-then-write race
- **Write-through**: Postgres is the source of truth, the sorted set is a derived
  view that must survive being rebuilt from it
- Filtering leaderboards by city, country, and time range

## Scaling Considerations (from the Source)

| Challenge | Solution |
|-----------|----------|
| 10M concurrent activities | Track locally on device, upload on completion |
| ~36.5B activities/year | Shard by time, data tiering (hot/warm/cold) |
| Real-time friend tracking | Polling every 2–5 s (not WebSockets—updates are predictable) |
| Leaderboard at scale | Redis Sorted Sets with ZINCRBY, separate sets per country |

## Honest Limits of This Lab

This is a teaching lab, not a fitness platform. What it deliberately does not do:

- **No map matching.** Tracks are never snapped to a road network.
- **Segments are two points and a length.** Real segment matching is a
  curve-similarity problem over the segment's full polyline; the distance-ratio
  check here catches the common detour, not a wrong-shaped route of the right length.
- **No cheat detection.** No speed sanity checks, so a car gets a KOM.
- **One row per GPS sample.** Real systems store activity streams column-wise or as
  encoded polyline blobs; a row per point does not survive 36B activities/year.
- **The benchmarks are shape, not scale.** With ~200 activities the Redis-vs-SQL
  timings are dominated by round-trip and planning, not data volume. The notebooks
  say so where they show numbers.

## License

Educational content — feel free to use and modify for learning purposes.
