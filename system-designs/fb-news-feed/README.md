# Facebook News Feed — System Design Lab

📖 **Source**: [Hello Interview – Design Facebook's News Feed](https://www.hellointerview.com/learn/system-design/problem-breakdowns/fb-news-feed)

## Overview

Facebook's News Feed shows recent posts from people you follow, sorted newest-first. It sounds simple, but at 2 billion users it's one of the hardest problems in system design: a single celebrity post must reach millions of feeds in under a minute.

This lab walks you through the core challenges — **fan-out**, **ranking**, **social graphs**, and **caching** — with real, runnable code backed by PostgreSQL and Redis.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Fan-Out on Write vs Read | The two strategies for building a feed, their trade-offs, and a hybrid approach |
| 2 | News Feed Ranking | Sorting posts by relevance instead of just time, simple scoring models |
| 3 | Social Graph Storage | Storing follow relationships, querying "who do I follow?" and "who follows me?" |
| 4 | Feed Caching Strategies | Using Redis to cache feeds, handling hot keys, cache invalidation |

## Architecture

```
┌──────────┐   HTTP    ┌──────────────┐  SQL    ┌────────────┐
│  Client   │─────────►│ Feed Service │◄───────►│ PostgreSQL │
│ (notebook)│          │  (Python)    │         │            │
└──────────┘          └──────┬───────┘         └────────────┘
                             │
                        cache / feed
                             │
                      ┌──────▼───────┐
                      │    Redis     │
                      └──────────────┘
```

## Core Concepts Covered

### Data Model
- **Users** — accounts that create posts and follow others
- **Follows** — uni-directional edges (follower → followee)
- **Posts** — text content with timestamps
- **Precomputed Feed** — materialised feed entries per user

### Fan-Out Strategies
| Strategy | When Feed Is Built | Best For |
|----------|-------------------|----------|
| **Fan-out on Read** | When the user opens their feed | Users who follow very few people |
| **Fan-out on Write** | When a post is created (pushed to followers' feeds) | Most regular users |
| **Hybrid** | Fan-out on write for normal users, fan-out on read for celebrities | Production systems at scale |

### Key Trade-offs
- **Write amplification** vs **read latency**
- **Storage cost** (precomputed feeds) vs **compute cost** (on-the-fly assembly)
- **Consistency** (how stale can a feed be?) vs **availability**

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd system-designs/fb-news-feed

# Start PostgreSQL + Redis + Visualization Tools
docker-compose up -d

# Install dependencies
uv sync

# Register Jupyter kernel
uv run python -m ipykernel install --user --name=newsfeed --display-name="News Feed (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `newsfeed_demo`
- **Use for**: Inspect users, follows, posts, and precomputed feed tables

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch cached feeds appear/expire, monitor TTLs, inspect sorted sets

## Real-World Context

| Concept | Why It Matters |
|---------|---------------|
| Fan-out on write | Instagram/Twitter precompute feeds for most users |
| Hybrid fan-out | Celebrities (Justin Bieber, Taylor Swift) skip write fan-out |
| Feed ranking | Facebook moved from chronological to ranked feeds in 2009 |
| Caching | A single viral post can generate millions of reads per second |

## License

Educational content — feel free to use and modify for learning purposes.
