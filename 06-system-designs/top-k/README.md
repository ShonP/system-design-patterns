# Top-K (YouTube's Most Viewed Videos)

📖 **Source**: [Hello Interview – Design YouTube's Top K Videos Feature](https://www.hellointerview.com/learn/system-design/problem-breakdowns/top-k)

## Overview

Top-K is one of the most common system design interview questions. The goal: given a massive stream of events (video views), find the K most popular items over different time windows (last hour, last day, all time).

This sounds simple — just count and sort! But at YouTube scale (70 billion views/day), counting becomes the hard part. You can't keep a counter for every video in memory, you can't sort billions of rows on every query, and you can't afford to lose data when servers crash.

This lab walks you through the building blocks — from clever data structures that approximate counts in tiny memory, to heap-based algorithms that maintain a running top-K, to distributed pipelines that shard the work across machines.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Count-Min Sketch | A probabilistic data structure that counts items using way less memory than a hash map |
| 2 | Heap-Based Top-K | Using a min-heap to efficiently track the K largest items from a stream |
| 3 | Distributed Top-K | Sharding, tumbling windows, Redis sorted sets, and caching precomputed results |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL and hash functions

## Quick Start

```bash
# Navigate to the lab directory
cd system-designs/top-k

# Start PostgreSQL + Redis + Visualization Tools
docker-compose up -d

# Install dependencies
uv sync

# Register Jupyter kernel
uv run python -m ipykernel install --user --name=top-k --display-name="Top-K (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `topk_demo`
- **Use for**: Inspect video tables, view counts, hourly aggregates

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch sorted sets update in real time, inspect Count-Min Sketch keys

## Key Concepts Covered

### The Core Problem
YouTube gets ~70 billion video views per day. That's ~700K views per second. We need to answer "What are the top K most-viewed videos?" for different time windows — fast.

### Why It's Hard
- **Too many items to count exactly** — billions of unique video IDs
- **Too many events to process one-by-one** — 700K writes/second overwhelms any single database
- **Queries must be fast** — users expect results in milliseconds, not minutes

### Data Structures
- **Count-Min Sketch** — approximate frequency counting in fixed memory using hash functions
- **Min-Heap** — efficiently maintain the top K items from a stream in O(n log k)
- **Redis Sorted Sets** — server-side sorted data structure perfect for leaderboards

### Architectural Patterns
- **Tumbling Windows** — divide time into fixed, non-overlapping buckets (e.g., each hour)
- **Sharding** — split data across multiple machines by video ID
- **Precomputation + Caching** — compute top-K periodically, serve from cache
- **Batching** — aggregate counts before writing to reduce database pressure

### Scale Estimates (from Hello Interview)
| Metric | Value |
|--------|-------|
| Views per day | 70 billion |
| Views per second | ~700K |
| Unique videos | ~3.6 billion |
| Naive storage (ID + count) | ~64 GB |
| Target query latency | <50 ms |

## Real-World Examples

| System | Top-K Use Case |
|--------|---------------|
| YouTube | Most viewed videos (hour / day / all time) |
| Twitter/X | Trending topics and hashtags |
| Spotify | Top charts (daily, weekly) |
| Amazon | Best-selling products by category |
| Google Search | Trending searches |

## Architecture Overview

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  View Events │────▶│   Aggregate  │────▶│  PostgreSQL   │
│  (Kafka)     │     │  (Batch/     │     │  (hourly_views│
│              │     │   Stream)    │     │   + totals)   │
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                  │
                                           ┌──────▼───────┐
                                           │  Top-K Cron  │
                                           │  (periodic   │
                                           │   compute)   │
                                           └──────┬───────┘
                                                  │
                                           ┌──────▼───────┐
┌──────────────┐                           │    Redis     │
│   Clients    │◀──────────────────────────│   (cache +   │
│  GET /top-k  │                           │  sorted sets)│
└──────────────┘                           └──────────────┘
```

## License

Educational content — feel free to use and modify for learning purposes.
