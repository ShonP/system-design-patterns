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
| 1 | Geospatial Search | PostGIS spatial indexes, Elasticsearch geo_distance, Redis caching, why B-trees fail for 2D data, why a lat/lon box is not a circle |
| 2 | Review & Rating Aggregation | Running average formula, a reproducible lost update, optimistic locking, drift-free integer sums, cache invalidation |
| 3 | Search Ranking & Relevance | BM25 text scoring, fuzzy matching, autocomplete (search-as-you-type), multi-signal ranking with function_score, index-vs-source-of-truth reconciliation |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd 06-system-designs/yelp

# Start PostgreSQL + Redis + Elasticsearch + Visualization Tools
docker compose up -d

# Install dependencies
uv sync

# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/

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
- **Bounding box ≠ circle** — a box with equal deltas on both axes is too narrow east–west
  (`lon_delta = lat_delta / cos(latitude)`) and too wide at the corners. Size it to *contain*
  the circle, then run an exact second-pass distance filter
- **Geohashing & Quadtrees** — alternative spatial indexing strategies (discussed conceptually)

### Rating Aggregation
- **On-the-fly AVG()** — simple but doesn't scale (joins millions of rows)
- **Cron batch update** — fast reads but stale data
- **Running average formula** — `new_avg = (old_avg × n + rating) / (n + 1)` — real-time updates
- **The lost update** — reproduced deterministically with a `threading.Barrier`: application-side
  read-modify-write silently drops concurrent reviews from the summary
- **Single-statement updates** — Postgres re-evaluates `SET` expressions under `READ COMMITTED`,
  so the same formula inside one `UPDATE` is already safe
- **Optimistic locking** — use `num_reviews` as a version number when the arithmetic must live in
  application code
- **Integer `rating_sum`** — addition commutes, so the average stops drifting with every rounding
- **Cache invalidation** — the write path has to delete the read path's cache entry
- **Database constraints** — enforce one-review-per-user-per-business at the persistence layer

### Search Ranking
- **BM25 / TF-IDF** — how Elasticsearch scores text relevance
- **Fuzzy matching** — handles typos using edit distance
- **Autocomplete (search-as-you-type)** — `match_phrase_prefix` for instant suggestions
- **Multi-signal ranking** — combine text match + distance + rating + review count
- **`function_score`** — Elasticsearch's custom ranking query, with the score recomputed by hand
  and checked against Elasticsearch (`log1p` is base 10; gaussian decay reaches `decay` at
  `offset + scale`, not at `scale`)

### Architecture Patterns
- **Scaling reads** — cache-aside pattern with Redis for search results and business details
- **Data sync** — Change Data Capture (CDC) to keep Elasticsearch in sync with Postgres, plus a
  runnable audit-and-repair pass that diffs the index against Postgres and re-indexes the drift
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

## Honest Limits of This Toy

- **500 businesses, 3,000 reviews.** At that size a sequential scan beats every index in the lab.
  Query *plans*, not wall-clock numbers, are the evidence that the indexes matter — the notebooks
  say so where it counts.
- **Synthetic text.** Every business shares one description, so BM25 has almost nothing to work
  with and relevance quality can't be measured here.
- **No relevance evaluation, no personalisation, no review moderation.**
- **Flat Earth-ish maths.** The hand-rolled bounding box uses 111,320 m per degree of latitude and
  breaks near the poles and across the antimeridian; PostGIS and Elasticsearch don't.
- **Seeded data.** `db/init.sql` calls `setseed(0.42)`, so `docker compose down -v && up -d`
  rebuilds essentially the same businesses and reviews rather than a fresh random world.

## License

Educational content — feel free to use and modify for learning purposes.
