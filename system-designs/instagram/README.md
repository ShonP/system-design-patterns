# Instagram — System Design Lab

📖 **Source**: [Hello Interview – Design Instagram](https://www.hellointerview.com/learn/system-design/problem-breakdowns/instagram)

## Overview

Instagram is a photo/video sharing platform where users post visual content and follow other users to see their posts in a chronological feed. At 500M daily active users and 100M posts per day, it combines the challenges of **large file storage**, **feed generation at scale**, and **low-latency media delivery**.

This lab walks you through the core building blocks — **photo upload pipelines**, **fan-out feed generation**, **ephemeral stories**, and **recommendation systems** — with real, runnable code backed by PostgreSQL, Redis, and MinIO (an S3-compatible object store).

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Photo Upload & Storage Pipeline | Pre-signed URLs, uploading to object storage, image thumbnails, the full upload flow |
| 2 | News Feed Generation | Fan-out on read vs write, hybrid celebrity approach, Redis sorted sets for feeds |
| 3 | Stories & Ephemeral Content | Time-to-live content, expiration with Redis TTL, efficient story ring queries |
| 4 | Explore & Recommendation | Collaborative filtering basics, engagement scoring, content discovery algorithms |

## Architecture

```
┌──────────┐   HTTP    ┌──────────────┐  SQL    ┌────────────┐
│  Client   │─────────►│ Post Service │◄───────►│ PostgreSQL │
│ (notebook)│          │  (Python)    │         │            │
└──────────┘          └──────┬───────┘         └────────────┘
                             │
                    cache / feed / stories
                             │
                      ┌──────▼───────┐
                      │    Redis     │
                      └──────────────┘
                             │
                      ┌──────▼───────┐
                      │ MinIO (S3)   │  ← photos & videos
                      └──────────────┘
```

## Core Concepts Covered

### Data Model
- **Users** — accounts that create posts and follow others
- **Follows** — uni-directional edges (follower → followee)
- **Posts** — photo/video metadata with captions
- **Media** — actual image/video bytes stored in MinIO (S3-compatible)
- **Stories** — ephemeral posts that expire after 24 hours
- **Precomputed Feed** — materialised feed entries per user

### Key Design Patterns
| Pattern | Where It Appears |
|---------|-----------------|
| **Pre-signed URLs** | Upload photos directly to object storage, bypassing the app server |
| **Fan-out on Write** | Push new posts into followers' precomputed feeds |
| **Hybrid Fan-out** | Fan-out on write for normal users, fan-out on read for celebrities |
| **TTL-based Expiration** | Stories auto-expire after 24 hours using Redis TTL |
| **Collaborative Filtering** | Recommend posts based on what similar users liked |

### Key Trade-offs
- **Write amplification** vs **read latency** (fan-out strategies)
- **Storage cost** (multiple image sizes) vs **bandwidth savings**
- **Consistency** (how stale can a feed be?) vs **availability**
- **Pre-computation** (explore scores) vs **freshness**

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd system-designs/instagram

# Start PostgreSQL + Redis + MinIO + Visualization Tools
docker-compose up -d

# Create virtual environment and install dependencies
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Register Jupyter kernel
python -m ipykernel install --user --name=instagram --display-name="Instagram (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `instagram_demo`
- **Use for**: Inspect users, follows, posts, and precomputed feed tables

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch cached feeds appear/expire, monitor TTLs, inspect sorted sets

### MinIO Console (Object Storage GUI)
- **URL**: http://localhost:9001
- **Login**: Username `minioadmin`, Password `minioadmin`
- **Use for**: Browse uploaded photos, inspect buckets, see storage usage

## Real-World Context

| Concept | Why It Matters |
|---------|---------------|
| Pre-signed URLs | Instagram uploads photos directly to S3, not through the app server |
| Hybrid fan-out | Celebrities (Ronaldo, Selena Gomez) skip write fan-out |
| CDN + image variants | Instagram serves different image sizes per device |
| Stories TTL | Ephemeral content auto-deletes, reducing storage costs |
| Explore algorithm | Drives discovery — users spend 50%+ of time on Explore |

## License

Educational content — feel free to use and modify for learning purposes.
