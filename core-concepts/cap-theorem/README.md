# CAP Theorem

📖 **Source**: [Hello Interview – CAP Theorem for System Design Interviews](https://www.hellointerview.com/learn/system-design/core-concepts/cap-theorem)

## Overview

CAP theorem states that in a distributed system, you can only have two out of three guarantees: **Consistency**, **Availability**, and **Partition Tolerance**. Since network partitions are unavoidable, the real choice boils down to: **do you prioritize consistency or availability?**

This lab lets you experience the trade-off hands-on. You'll write to a PostgreSQL primary, read from a replica, simulate network partitions, and see exactly what happens to your data.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Understanding CAP Trade-offs | What C, A, P mean, why you must pick two, real-world examples |
| 2 | Consistency vs Availability Demo | Replication lag, simulated partitions, CP vs AP behavior |
| 3 | Choosing the Right Database | How to pick CP or AP for your use case, consistency levels |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd core-concepts/cap-theorem

# Start PostgreSQL primary + replica + Redis + Visualization Tools
docker-compose up -d

# Create virtual environment and install dependencies
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Register Jupyter kernel
python -m ipykernel install --user --name=cap-theorem --display-name="CAP Theorem (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres-primary`, Username `demo`, Password `demo`, Database `cap_demo`
- **Use for**: Watch data on the primary, compare with the replica

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch cache keys, observe AP-style behavior with Redis

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                   Docker Network                      │
│                                                      │
│  ┌─────────────┐   streaming     ┌──────────────┐   │
│  │  PostgreSQL  │──replication──▶│  PostgreSQL   │   │
│  │   Primary    │                │   Replica     │   │
│  │  (writes)    │                │  (reads only) │   │
│  │  port 5432   │                │  port 5433    │   │
│  └─────────────┘                └──────────────┘   │
│                                                      │
│  ┌─────────────┐                                    │
│  │    Redis     │  (AP-style cache, always available)│
│  │  port 6379   │                                    │
│  └─────────────┘                                    │
└──────────────────────────────────────────────────────┘
```

## Key Concepts Covered

### The CAP Triangle
- **Consistency (C)**: Every read returns the most recent write
- **Availability (A)**: Every request gets a response (even if stale)
- **Partition Tolerance (P)**: System works despite network failures

### The Real Choice: CP vs AP
- **CP (Consistency + Partition Tolerance)**: Returns errors or blocks during partitions to guarantee accuracy
- **AP (Availability + Partition Tolerance)**: Always responds but may serve stale data

### When to Choose Consistency
- Ticket/seat booking systems
- Financial transactions
- Inventory management

### When to Choose Availability
- Social media profiles
- Content platforms
- Review/rating sites

### Consistency Levels
- **Strong Consistency**: All reads see the latest write
- **Causal Consistency**: Related events appear in the correct order
- **Read-Your-Own-Writes**: You see your own updates immediately
- **Eventual Consistency**: Data converges over time

## Real-World Examples

| System | CP or AP | Why |
|--------|----------|-----|
| Bank transfers | CP | Can't show wrong balance |
| Ticket booking | CP | Can't double-book a seat |
| Social media feed | AP | Stale post count is fine temporarily |
| Netflix catalog | AP | Old description is better than no page |
| Stock trading | CP | Stale prices cause real money loss |
| DNS | AP | Temporary stale records are acceptable |

## License

Educational content — feel free to use and modify for learning purposes.
