# Yelp

📖 **Source**: [Hello Interview – Yelp System Design](https://www.hellointerview.com/learn/system-design/problem-breakdowns/yelp)

## Overview

Yelp is an online platform where users **search for local businesses**, **view details and reviews**, and **leave their own reviews**. It sounds simple, but building a fast, accurate search system for 10M businesses and 100M daily users requires solving some interesting engineering problems.

The three big challenges:
1. **Geospatial search** — How do you quickly find businesses within 2 km of a user? Traditional database indexes don't work well for 2D location data.
2. **Rating aggregation** — How do you keep average ratings accurate and up-to-date without re-scanning millions of reviews on every query?
3. **Search ranking** — When a user searches "pizza," hundreds of businesses match. How do you rank them by relevance, distance, AND quality?

This lab walks you through all three with real, runnable code.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Geospatial Search | PostGIS spatial indexes, Elasticsearch geo_distance, Redis caching, why B-trees fail for 2D data |
| 2 | Review & Rating Aggregation | Running average formula, optimistic locking for concurrent updates, database constraints |
| 3 | Search Ranking & Relevance | BM25 text scoring, fuzzy matching, multi-signal ranking with function_score |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd system-designs/yelp

# Start PostgreSQL + Redis + Elasticsearch + Visualization Tools
docker-compose up -d

# Create virtual environment and install dependencies
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Register Jupyter kernel
python -m ipykernel install --user --name=yelp --display-name="Yelp (Python)"

# Open the first notebook and start learning!
```

> **Note**: Elasticsearch may take 30–60 seconds to start. Wait until `curl http://localhost:9200` returns a response before running the notebooks.

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `yelp_demo`
- **Use for**: Explore business and review data, run queries, see indexes

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch cache keys appear/expire, monitor search result caching

## Key Concepts Covered

### Geospatial Search
- **B-tree indexes** — work for 1D data but fail for lat/lon queries
- **R-tree / GIST indexes** (PostGIS) — designed for multi-dimensional spatial data
- **Elasticsearch geo_distance** — purpose-built for location search at scale
- **Geohashing & Quadtrees** — alternative spatial indexing strategies (discussed conceptually)

### Rating Aggregation
- **On-the-fly AVG()** — simple but doesn't scale (joins millions of rows)
- **Cron batch update** — fast reads but stale data
- **Running average formula** — `new_avg = (old_avg × n + rating) / (n + 1)` — real-time updates
- **Optimistic locking** — prevents data corruption from concurrent reviews
- **Database constraints** — enforce one-review-per-user-per-business at the persistence layer

### Search Ranking
- **BM25 / TF-IDF** — how Elasticsearch scores text relevance
- **Fuzzy matching** — handles typos using edit distance
- **Multi-signal ranking** — combine text match + distance + rating + review count
- **`function_score`** — Elasticsearch's custom ranking query

### Architecture Patterns
- **Scaling reads** — cache-aside pattern with Redis for search results and business details
- **Data sync** — Change Data Capture (CDC) to keep Elasticsearch in sync with Postgres
- **Filter sequence** — apply the most restrictive filter first (distance → category → text)

## Architecture

```
User Search Request
        │
        ▼
   ┌─────────┐     cache hit     ┌────────┐
   │  Redis   │◄─────────────────│ API GW │
   │  Cache   │                  └────┬───┘
   └─────────┘                        │ cache miss
                                      ▼
                              ┌───────────────┐
                              │ Elasticsearch  │  ← geo_distance + text match + function_score
                              └───────┬───────┘
                                      │ CDC sync
                                      ▼
                              ┌───────────────┐
                              │  PostgreSQL    │  ← source of truth (businesses, reviews, users)
                              └───────────────┘
```

## Real-World Insights

| Insight | Why It Matters |
|---------|---------------|
| Write volume is tiny (~1 review/sec) | No need for message queues — direct DB writes are fine |
| Data size is small (~1 TB) | No need for sharding — single Postgres instance works |
| Read:write ratio is ~1000:1 | Caching + read replicas solve the scaling problem |
| Postgres extensions (PostGIS, pg_trgm) | Can avoid Elasticsearch entirely for simpler setups |

## License

Educational content — feel free to use and modify for learning purposes.
