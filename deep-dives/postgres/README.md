# PostgreSQL Deep Dive

📖 **Source**: [Hello Interview – PostgreSQL Deep Dive for System Design Interviews](https://www.hellointerview.com/learn/system-design/deep-dives/postgres)

## Overview

PostgreSQL is consistently ranked as the most beloved database in Stack Overflow's developer survey. It powers companies from Reddit to Instagram. But knowing SQL is not enough — you need to understand **indexing**, **query optimization**, **replication**, and **partitioning** to design systems that scale.

This lab teaches each topic using the **bad → better → best** pattern: you'll see the naive approach first, understand why it fails, and then learn progressively better solutions.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Indexing Fundamentals | Full table scans → B-tree indexes → composite/partial/covering indexes |
| 2 | Query Optimization | N+1 queries → JOINs → CTEs and window functions |
| 3 | Replication & Failover | Single server → streaming replication → failover |
| 4 | Partitioning Strategies | One huge table → range/list/hash partitioning |

Each notebook follows the **BAD → BETTER → BEST** pattern with real `EXPLAIN ANALYZE` output so you can see exactly how each improvement helps.

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│  PostgreSQL      │────▶│  PostgreSQL      │
│  PRIMARY         │ WAL │  REPLICA         │
│  (read + write)  │     │  (read-only)     │
│  localhost:5432  │     │  localhost:5433   │
└─────────────────┘     └─────────────────┘
        │
        │
┌───────┴─────────┐     ┌─────────────────┐
│  pgAdmin 4       │     │  Adminer         │
│  localhost:5050  │     │  localhost:8080  │
└─────────────────┘     └─────────────────┘
```

## Quick Start

```bash
# Navigate to the lab directory
cd deep-dives/postgres

# Start PostgreSQL primary + replica + visualization tools
docker-compose up -d

# Wait ~30 seconds for the replica to finish base backup

# Install dependencies
uv sync

# Register Jupyter kernel
uv run python -m ipykernel install --user --name=postgres-deep-dive --display-name="PostgreSQL Deep Dive (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### pgAdmin 4 (PostgreSQL GUI)
- **URL**: http://localhost:5050
- **Login**: Email `admin@demo.com`, Password `admin`
- **Add Server**: Host `postgres-primary`, Port `5432`, Username `demo`, Password `demo`
- **Use for**: Visual EXPLAIN plans, server monitoring, query execution

### Adminer (Lightweight SQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres-primary`, Username `demo`, Password `demo`, Database `postgres_demo`
- **Use for**: Quick queries, table browsing, data exploration

## Database Schema

The lab uses a **social media platform** schema:

| Table | Rows | Purpose |
|-------|------|---------|
| `users` | 5,000 | User profiles with verification status |
| `posts` | 100,000 | User posts with status, likes, views |
| `comments` | 200,000 | Comments on posts |
| `follows` | ~30,000 | Follower/following relationships |
| `likes` | ~300,000 | Post likes |
| `direct_messages` | 50,000 | Private messages between users |

**No indexes are pre-created** (except primary keys) — the notebooks create them to demonstrate before/after performance.

## Key Concepts Covered

### Indexing
- **B-tree indexes** — the default, good for equality and range queries
- **Composite indexes** — multi-column indexes for common query patterns
- **Partial indexes** — index only the rows you query most
- **Covering indexes** — include extra columns to avoid table lookups (Index-Only Scan)

### Query Optimization
- **EXPLAIN ANALYZE** — how to read query execution plans
- **N+1 problem** — why loops of queries kill performance
- **JOIN strategies** — Nested Loop vs Hash Join vs Merge Join
- **Window functions** — analytics without subqueries

### Replication
- **Streaming replication** — real-time WAL shipping to replicas
- **Read scaling** — distribute reads across replicas
- **Replication lag** — monitoring and handling stale reads
- **Failover** — promoting a replica to primary

### Partitioning
- **Range partitioning** — split by date/time ranges
- **List partitioning** — split by category/status values
- **Hash partitioning** — distribute evenly across partitions
- **Partition pruning** — how Postgres skips irrelevant partitions

## Cleanup

```bash
# Stop all containers and remove data
docker-compose down -v
```

## License

Educational content — feel free to use and modify for learning purposes.
