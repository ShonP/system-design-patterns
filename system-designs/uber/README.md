# Design a Ride-Sharing Service Like Uber

📖 **Source**: [Hello Interview – Uber System Design](https://www.hellointerview.com/learn/system-design/problem-breakdowns/uber)

## Overview

Uber connects riders with nearby drivers in real time. Behind the simple "Request Ride" button is a system that must handle millions of GPS updates per second, match riders to optimal drivers in under a minute, adjust pricing dynamically based on demand, and track every ride through a multi-step lifecycle — all while preventing race conditions where two rides get assigned to the same driver.

This lab lets you build and experiment with the core pieces yourself using real tools: **PostGIS** for geospatial queries, **Redis** for real-time location tracking and distributed locking, and **PostgreSQL** for durable ride state.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Geospatial Matching | PostGIS spatial queries, Redis GEOADD/GEOSEARCH, finding nearest drivers |
| 2 | Real-Time Driver Tracking | High-frequency location updates, Redis geo commands, staleness cleanup |
| 3 | Surge Pricing | Supply/demand calculation, dynamic multipliers, zone-based pricing |
| 4 | Trip Lifecycle Management | Ride state machine, distributed locking with Redis TTL, preventing double-assignment |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL and coordinates (latitude/longitude)

## Quick Start

```bash
# Navigate to the lab directory
cd system-designs/uber

# Start PostgreSQL (with PostGIS) + Redis + Visualization Tools
docker-compose up -d

# Create virtual environment and install dependencies
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Register Jupyter kernel
python -m ipykernel install --user --name=uber --display-name="Uber Lab (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `uber_demo`
- **Use for**: Explore the schema, run spatial queries, watch ride status changes

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch driver locations in geo sets, see lock keys with TTLs, monitor real-time updates

## Key Concepts Covered

### Geospatial Data
- **PostGIS** — PostgreSQL extension for geographic data types and spatial queries
- **Redis Geo** — In-memory geospatial index using GEOADD / GEOSEARCH
- **SRID 4326** — The coordinate reference system for GPS (latitude/longitude on Earth)
- **ST_DWithin / ST_Distance** — PostGIS functions for proximity searches

### Real-Time Location Tracking
- **High-frequency writes** — Millions of drivers sending GPS every 5 seconds
- **Redis as write buffer** — Absorb 2M writes/sec that would overwhelm a database
- **Staleness detection** — Removing drivers who stop sending updates

### Surge Pricing
- **Supply/Demand ratio** — Available drivers vs. ride requests per zone
- **Dynamic multipliers** — Price goes up when demand exceeds supply
- **Zone-based pricing** — Different parts of the city have different surge levels

### Ride Lifecycle & Consistency
- **State machine** — requested → matching → accepted → en_route → in_progress → completed
- **Distributed locks** — Redis SET with NX and EX to prevent double-assignment
- **TTL-based locks** — Locks auto-expire if a driver doesn't respond in time

## Architecture Overview

```
┌──────────┐     ┌──────────┐
│  Rider   │     │  Driver  │
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
│   Ride     │  │   Location   │
│  Service   │  │   Service    │
└──────┬─────┘  └──────┬───────┘
       │               │
       ▼               ▼
┌────────────┐  ┌──────────────┐
│ PostgreSQL │  │    Redis     │
│ + PostGIS  │  │  (Geo Sets)  │
└────────────┘  └──────────────┘
```

## Real-World Scale

| Metric | Value |
|--------|-------|
| Active drivers | ~5 million globally |
| Location updates | ~2 million/second |
| Ride requests (peak) | ~100k from one area during events |
| Match latency target | < 1 minute |
| Location freshness | < 5 seconds |

## License

Educational content — feel free to use and modify for learning purposes.
