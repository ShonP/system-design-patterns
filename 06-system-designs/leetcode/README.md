# Design a Coding Platform Like LeetCode

📖 **Source**: [Hello Interview – LeetCode System Design](https://www.hellointerview.com/learn/system-design/problem-breakdowns/leetcode)

## Overview

LeetCode is a platform where users solve coding problems, submit solutions, and compete on leaderboards. The interesting system design challenges are:

1. **Running untrusted user code safely** — you cannot just `exec()` random code on your servers.
2. **Returning results fast** — submissions should finish within 5 seconds even though they run inside isolated containers.
3. **Real-time leaderboards** — during a contest with 100k users, the ranking page must update every few seconds without crushing the database.

This lab walks you through each challenge with runnable Python code, a real PostgreSQL database, a Redis cache, and a locked-down sandbox container.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Code Submission & Execution Pipeline | Requirements + contest capacity estimate, API → queue → worker → container, async job polling |
| 2 | Sandboxed Code Execution | Running untrusted code in a real locked-down container: read-only FS, memory/CPU/pid limits, no network |
| 3 | Leaderboards & Contest System | Redis sorted sets, score encoding, polling vs WebSockets, and sizing on **throughput** rather than round-trip latency |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL and Redis

## Quick Start

```bash
# Navigate to the lab directory
cd 06-system-designs/leetcode

# Start PostgreSQL + Redis + Sandbox + Visualization Tools
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
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `leetcode_demo`
- **Use for**: Browse problems, inspect submissions, watch leaderboard queries

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch sorted-set leaderboard keys, monitor TTLs, see real-time updates

## Architecture Diagram

```
┌──────────┐       ┌────────────┐       ┌────────────┐
│  Client   │──────▶│  API Server │──────▶│  Database   │
│ (browser) │◀──────│  (FastAPI)  │◀──────│ (Postgres)  │
└──────────┘       └─────┬──────┘       └────────────┘
                         │
                    ┌────▼────┐
                    │  Queue   │   (simulated in-memory)
                    └────┬────┘
                         │
                    ┌────▼─────┐      ┌────────────┐
                    │  Worker   │─────▶│  Sandbox    │
                    │ (Python)  │◀─────│ (Container) │
                    └────┬─────┘      └────────────┘
                         │
                    ┌────▼────┐
                    │  Redis   │   sorted sets for leaderboards
                    └─────────┘
```

## Key Concepts Covered

### Code Execution Approaches
- **Direct execution** — simple but dangerously insecure ❌
- **Virtual machines** — safe but slow to start and resource-heavy
- **Containers** — fast, lightweight, good isolation ✅ (our choice)
- **Serverless functions** — auto-scaling but cold-start latency

### Sandbox Security Layers
- **Read-only filesystem** — prevents writing to the host
- **CPU & memory limits** — stops infinite loops / memory bombs
- **No network access** — blocks data exfiltration
- **Seccomp / no-new-privileges** — restricts system calls
- **Explicit timeout** — kills long-running processes

### Leaderboard Strategies
- **Query DB every request** — simple but crushes the database under load
- **Periodic cache refresh** — reduces DB load but stale data
- **Redis sorted sets** — real-time ranking with O(log N) updates ✅ (our choice)

## Real-World Numbers

| Metric | Value |
|--------|-------|
| Problems | ~4,000 |
| Registered users | ~500k |
| Contest participants | up to 100k |
| Submission result target | < 5 seconds |
| Contest duration | 90 minutes |
| Leaderboard refresh | every 5 seconds (client polling) |
| Peak submissions during a contest | ~550/s → ~1,100 concurrent sandboxes (Notebook 1 computes this) |

## License

Educational content — feel free to use and modify for learning purposes.
