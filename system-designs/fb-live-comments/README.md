# Facebook Live Comments System Design

📖 **Source**: [Hello Interview – Design Facebook's Live Comments System](https://www.hellointerview.com/learn/system-design/problem-breakdowns/fb-live-comments)

## Overview

Facebook Live Comments lets viewers post and see comments on a live video in near-real-time. It sounds simple — just save a comment and show it to everyone — but at scale this becomes one of the most interesting system design problems out there.

Think about it: millions of people watching the same live video, thousands of comments pouring in every second, and every viewer expects to see new comments appear almost instantly. How do you build that?

This lab walks you through the core challenges step by step with runnable code.

## What You'll Learn

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Real-Time Comment Streaming | SSE vs WebSockets, pub/sub with Redis, building a live comment feed |
| 2 | Comment Ordering & Pagination | Cursor vs offset pagination, why ordering matters, infinite scroll |
| 3 | Scaling Live Comments | Horizontal scaling, pub/sub fan-out, mega-stream strategies |

## Core Entities

- **User** — a viewer or broadcaster
- **Live Video** — the video being streamed (owned by a broadcaster)
- **Comment** — a message posted by a user on a live video

## API Design

```
POST /comments/:liveVideoId          # Post a new comment
GET  /comments/:liveVideoId           # Fetch past comments (paginated)
     ?cursor={last_comment_id}
     &pageSize=10
     &sort=desc
SSE  /stream/:liveVideoId             # Real-time comment stream
```

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL and HTTP

## Quick Start

```bash
# Navigate to the lab directory
cd system-designs/fb-live-comments

# Start PostgreSQL + Redis + Visualization Tools
docker-compose up -d

# Create virtual environment and install dependencies
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Register Jupyter kernel
python -m ipykernel install --user --name=fb-live-comments --display-name="FB Live Comments (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `live_comments`
- **Use for**: Inspect comments table, watch rows appear, run queries

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch pub/sub channels, inspect cached comment snapshots, monitor real-time activity

## Key Concepts Covered

### Real-Time Delivery
- **Polling** — simple but wasteful; client asks "any new comments?" repeatedly
- **WebSockets** — full-duplex; overkill when reads >> writes
- **Server-Sent Events (SSE)** — one-way push from server; ideal for live comment feeds

### Pagination
- **Offset pagination** — simple but unstable in fast-moving feeds
- **Cursor pagination** — stable, efficient, scales with comment volume

### Scaling Strategies
- **Pub/Sub** (Redis) — broadcast comments to all connected servers
- **Channel partitioning** — reduce fan-out by hashing video IDs to channels
- **Viewer co-location** — route viewers of the same video to the same server
- **Comment sampling** — at mega-scale, show a representative subset
- **CDN snapshots** — for viral streams, switch from push to pull via CDN

### Disconnection Handling
- **Last-Event-ID** — SSE's built-in reconnection mechanism
- **Client-side tracking** — remember last seen comment for catch-up
- **Bounded replay** — replay recent comments, not the entire history

## Architecture at a Glance

```
┌──────────┐     POST /comments      ┌─────────────────────┐     INSERT     ┌──────────┐
│  Client   │ ──────────────────────▶ │  Comment Management │ ────────────▶ │ Postgres │
│ (Viewer)  │                         │      Service        │               └──────────┘
└──────────┘                         └─────────────────────┘
     ▲                                         │
     │ SSE                                     │ PUBLISH
     │                                         ▼
┌──────────┐    subscribe to channel   ┌──────────┐
│ Realtime  │ ◀─────────────────────── │  Redis   │
│ Messaging │                          │  Pub/Sub │
│  Server   │                          └──────────┘
└──────────┘
```

## License

Educational content — feel free to use and modify for learning purposes.
