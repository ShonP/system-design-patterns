# News Aggregator — System Design Lab

📖 **Source**: [Hello Interview – Design a News Aggregator](https://www.hellointerview.com/learn/system-design/problem-breakdowns/news-aggregator)

## Overview

A news aggregator collects articles from hundreds of RSS feeds, removes duplicates, ranks them by freshness and relevance, and serves a personalised feed to each user. Think Google News or Apple News.

The hard parts: crawling thousands of sources without getting rate-limited, detecting that five outlets are reporting the *same* story, and building a feed that feels tailor-made — all at low latency.

This lab walks you through the three core pipelines — **ingestion**, **deduplication + ranking**, and **personalised feed generation** — with real, runnable code backed by PostgreSQL and Redis.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | RSS Feed Crawling & Parsing | Fetch and parse RSS/Atom feeds, normalise data, store articles, schedule crawls with Redis |
| 2 | Content Deduplication & Ranking | Hash-based and text-similarity dedup, freshness/popularity ranking |
| 3 | Personalised Feed Generation | User interest profiles, scoring articles, assembling and caching feeds with Redis |

## Architecture

```
RSS Feeds ──►  ┌──────────────┐  SQL   ┌────────────┐
(Internet)     │   Crawler /   │◄─────►│ PostgreSQL │
               │   Normaliser  │       └────────────┘
               └──────┬───────┘
                      │ dedup + rank
               ┌──────▼───────┐
               │  Feed Builder │──────►┌───────┐
               │  (per-user)   │       │ Redis │  ← cached feeds
               └──────┬───────┘       └───────┘
                      │
               ┌──────▼───────┐
               │   Client      │
               │  (notebook)   │
               └──────────────┘
```

## Core Concepts Covered

### Data Ingestion
- RSS/Atom feed parsing with `feedparser`
- Content normalisation (dates, authors, summaries)
- Crawl scheduling with Redis sorted sets
- Handling feed failures and back-off

### Content Deduplication
- **Exact dedup** — SHA-256 hash of normalised text
- **Near-duplicate detection** — shingling + Jaccard similarity
- Grouping duplicates and selecting a canonical article
- Boosting source count for widely-reported stories

### Ranking
- **Freshness score** — exponential time decay
- **Popularity score** — source count + interaction count
- **Combined score** — weighted blend of freshness + popularity

### Personalised Feed
- User interest profiles (category weights)
- Content-based scoring (article categories × user interests)
- Implicit feedback from click/read/bookmark history
- Redis-cached feeds with TTL for fast serving

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd system-designs/news-aggregator

# Start PostgreSQL + Redis + Visualization Tools
docker-compose up -d

# Create virtual environment and install dependencies
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Register Jupyter kernel
python -m ipykernel install --user --name=newsagg --display-name="News Aggregator (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `newsagg_demo`
- **Use for**: Browse articles, check duplicate groups, inspect user interactions

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch crawl schedules, cached feeds, and TTLs in real time

## Key Trade-offs to Discuss in Interviews

| Trade-off | Option A | Option B |
|-----------|----------|----------|
| Crawl frequency | More frequent → fresher news, higher cost | Less frequent → stale but cheaper |
| Dedup strictness | Strict → fewer duplicates, risk merging different stories | Loose → some duplicates slip through |
| Feed freshness | Pre-compute feeds → fast reads, stale data | Compute on read → always fresh, higher latency |
| Consistency | Eventually consistent → faster, simpler | Strong consistency → complex, slower |

## Real-World Context

| Concept | Why It Matters |
|---------|---------------|
| Crawl scheduling | Google News crawls millions of sources at different frequencies |
| Content dedup | The same breaking story appears on 50+ outlets simultaneously |
| Ranking | Users expect the most relevant, freshest stories at the top |
| Personalisation | Apple News, Google News, and Flipboard all tailor feeds per user |
| Caching | A trending story generates millions of feed requests per minute |

## License

Educational content — feel free to use and modify for learning purposes.
