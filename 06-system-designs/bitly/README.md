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
| 1 | URL Encoding & Hash Generation | Requirements + back-of-envelope, Base62, hash vs counter codes, birthday-paradox collisions |
| 2 | Redirect Service with Caching | 301 vs 302, Cache-Aside, negative caching, custom-alias contention (TOCTOU race + fix) |
| 3 | Analytics & Click Tracking | Sync vs async tracking, write-behind, Redis counter drift, real-time top-N |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd 06-system-designs/bitly

# Start PostgreSQL + Redis + Visualization Tools
docker compose up -d

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

Notebook 1 computes all of these from stated assumptions — run the cell rather
than trusting the table.

| Metric | Value | Where it comes from |
|--------|-------|---------------------|
| Read/Write ratio | 1000:1 | assumption |
| New URLs/day | 100M | assumption |
| Write throughput | ~1,157/s avg, ~3,472/s peak | 100M ÷ 86,400, ×3 for peak |
| Read throughput | ~1.16M/s avg, ~3.47M/s peak | write QPS × 1000 |
| Storage (5 years) | ~91 TB | 100M/day × 500 B × 365 × 5 |
| Egress on redirects | ~4.6 Gbps | 1.16M/s × 500 B × 8 |
| Short code length | **7 characters** | 182.5B codes needed; 62⁶ = 56.8B is too small, 62⁷ = 3.52T gives 19× headroom |
| Hot cache working set | ~5 GB | 10M hot links × 500 B — fits one Redis node |
| Target redirect latency | p99 < 100 ms | non-functional requirement |
| Availability target | 99.99% (reads) | non-functional requirement |

## License

Educational content — feel free to use and modify for learning purposes.
