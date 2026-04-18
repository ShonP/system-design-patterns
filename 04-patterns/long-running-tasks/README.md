# 🏃 Managing Long Running Tasks

Learn how to handle operations that take seconds to hours without blocking your API.

## The Problem

When a user clicks "Generate Report" and it takes 45 seconds, synchronous processing fails:
- HTTP timeouts kill the request
- Users have no feedback
- Retries create duplicate work
- One slow operation blocks everything

```
❌ SYNCHRONOUS (Bad)
┌────────┐    45 seconds...    ┌────────┐
│ Client │ ──────────────────> │ Server │ Processing...
│   😰   │     (timeout!)      │   💥   │
└────────┘                     └────────┘

✅ ASYNCHRONOUS (Good)
┌────────┐  100ms   ┌────────┐         ┌─────────┐
│ Client │ ───────> │ Server │ ──────> │  Queue  │
│   😊   │ job_id   │        │  push   │         │
└────────┘          └────────┘         └────┬────┘
                                            │
    ┌───────────────────────────────────────┘
    │ pull
    ▼
┌─────────┐         ┌──────────┐
│ Worker  │ ──────> │ Database │
│ (async) │ update  │ (status) │
└─────────┘         └──────────┘
```

## What You'll Learn

| Notebook | Topic | Key Concepts |
|----------|-------|--------------|
| 01 | The Sync Problem | Why sync fails, timeout math |
| 02 | Queue Basics | Redis queue, job submission |
| 03 | Worker Implementation | Polling, processing, status updates |
| 04 | Failure Handling | Retries, heartbeats, visibility timeout |
| 05 | Dead Letter Queues | Poison messages, isolation |
| 06 | Advanced Patterns | Idempotency, backpressure, priorities |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        API Server                            │
│  1. Validate request                                         │
│  2. Create job record (status: pending)                      │
│  3. Push job_id to queue                                     │
│  4. Return job_id immediately                                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Redis Queue                              │
│  • Durable storage                                           │
│  • Visibility timeout                                        │
│  • Priority support                                          │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │ Worker 1 │   │ Worker 2 │   │ Worker 3 │
        └──────────┘   └──────────┘   └──────────┘
              │               │               │
              └───────────────┼───────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     PostgreSQL                               │
│  • Job status tracking                                       │
│  • Results storage                                           │
│  • Audit trail                                               │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# Start Redis and PostgreSQL
docker compose up -d

# Install dependencies
uv sync

# Open notebooks in order
```

## Services

| Service | URL | Credentials |
|---------|-----|-------------|
| Redis | localhost:6379 | - |
| RedisInsight | http://localhost:5540 | - |
| PostgreSQL | localhost:5432 | postgres / postgres |
| Adminer | http://localhost:8080 | postgres / postgres / taskqueue |

## Real-World Applications

- **YouTube**: Video transcoding (multiple resolutions, thumbnails)
- **Instagram**: Photo processing, feed fanout to millions
- **Stripe**: Fraud detection, webhook delivery
- **Dropbox**: File sync, virus scanning, preview generation
- **Uber**: Ride matching, driver assignment
