# Design a URL Shortener (Bitly)

📖 **Source**: [Hello Interview – Design a URL Shortener Like Bit.ly](https://www.hellointerview.com/learn/system-design/problem-breakdowns/bitly)

## Overview

A URL shortener turns long URLs into short, shareable links (e.g., `short.ly/abc123`). It sounds simple, but under the hood it's a great system design problem because it touches:

- **Encoding & hashing** — how to generate short, unique codes
- **Read-heavy scaling** — 1000 clicks for every 1 URL created
- **Caching** — serving redirects from Redis instead of hitting the database
- **Analytics** — tracking clicks without slowing down redirects

This lab walks you through all of it with real, runnable code.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | URL Encoding & Hash Generation | Base62 encoding, hash-based vs counter-based short codes, collision handling |
| 2 | Redirect Service with Caching | HTTP redirects (301 vs 302), Cache-Aside pattern, FastAPI redirect service |
| 3 | Analytics & Click Tracking | Sync vs async tracking, Redis counters, write-behind pattern, SQL analytics |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd system-designs/bitly

# Start PostgreSQL + Redis + Visualization Tools
docker-compose up -d

# Create virtual environment and install dependencies
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Register Jupyter kernel
python -m ipykernel install --user --name=bitly --display-name="Bitly (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `bitly_demo`
- **Use for**: Browse the `urls` and `clicks` tables, run SQL queries

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch cache keys, monitor the click queue, see real-time counters

## Key Concepts Covered

### URL Encoding
- **Base62** — URL-safe encoding using `a-z A-Z 0-9` (no special characters)
- **Hash + truncate** — SHA-256 produces a fixed-size hash, take first N characters
- **Counter + encode** — atomic Redis counter guarantees uniqueness with zero collisions

### Redirect Flow
- **302 Found** — temporary redirect, every click goes through your server (enables analytics)
- **301 Moved Permanently** — browser caches it, future clicks skip your server
- **Cache-Aside** — check Redis first, fall back to PostgreSQL on miss

### Analytics
- **Sync tracking** — write click data to DB before responding (simple, slow)
- **Async tracking** — push to Redis queue, flush to DB in background (fast)
- **Write-Behind** — clicks go to Redis immediately, batch-inserted to PostgreSQL later
- **Redis counters** — instant total click counts via `INCR`

## Architecture

```
┌──────────┐     ┌──────────────────┐     ┌───────────┐
│  Client   │────→│  FastAPI Server   │────→│   Redis   │
│ (Browser) │←────│                  │     │  • Cache   │
└──────────┘ 302  │  POST /shorten   │     │  • Counter │
                   │  GET  /{code}    │     │  • Queue   │
                   └──────────────────┘     └─────┬─────┘
                            │                     │
                            │                     │ flush
                            ▼                     ▼
                   ┌──────────────────────────────────┐
                   │         PostgreSQL               │
                   │  • urls table (short→long)       │
                   │  • clicks table (analytics)      │
                   └──────────────────────────────────┘
```

## Real-World Numbers

| Metric | Value |
|--------|-------|
| Read/Write ratio | 1000:1 |
| Target redirect latency | < 100ms |
| Short code length | 6–7 characters |
| Code space (7 chars) | 62⁷ ≈ 3.5 trillion |
| Availability target | 99.99% |

## License

Educational content — feel free to use and modify for learning purposes.
