# Sharding

📖 **Source**: [Hello Interview – Sharding in System Design Interviews](https://www.hellointerview.com/learn/system-design/core-concepts/sharding)

## Overview

Your app is taking off. Traffic is growing and your database keeps getting bigger. You upgrade to a larger instance but eventually hit the ceiling of what a single machine can handle. Queries slow down, writes bottleneck, and storage hits its limit.

**Sharding** solves this by splitting your data across multiple machines. Each shard holds a subset of the data, and together they make up the full dataset. This lab walks you through sharding strategies with real, runnable code against actual Postgres instances.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Hash-Based Sharding | Even distribution using hash functions, shard routing |
| 2 | Range-Based Sharding | Splitting data by value ranges, pros and cons |
| 3 | Consistent Hashing | Minimizing data movement when adding/removing shards |
| 4 | Rebalancing Strategies | How to handle growth, split shards, migrate data |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd core-concepts/sharding

# Start 3 PostgreSQL shards + Adminer
docker-compose up -d

# Create virtual environment and install dependencies
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Register Jupyter kernel
python -m ipykernel install --user --name=sharding --display-name="Sharding (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Shard 1**: Server `shard-1`, Username `demo`, Password `demo`, Database `shard_1`
- **Shard 2**: Server `shard-2`, Username `demo`, Password `demo`, Database `shard_2`
- **Shard 3**: Server `shard-3`, Username `demo`, Password `demo`, Database `shard_3`
- **Use for**: See how data is distributed across shards, compare row counts

## Architecture

```
                    ┌──────────────┐
                    │  Application │
                    │  (Notebook)  │
                    └──────┬───────┘
                           │
                    ┌──────┴───────┐
                    │ Shard Router │
                    │  (Python)   │
                    └──────┬───────┘
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │ Shard 1  │ │ Shard 2  │ │ Shard 3  │
        │ Postgres │ │ Postgres │ │ Postgres │
        │ :5433    │ │ :5434    │ │ :5435    │
        └──────────┘ └──────────┘ └──────────┘
```

## Key Concepts Covered

### Choosing a Shard Key
- **High cardinality** — many unique values (e.g., user_id)
- **Even distribution** — values spread evenly across shards
- **Aligns with queries** — most common queries hit a single shard

### Sharding Strategies
- **Hash-Based** — `shard = hash(key) % num_shards` — even distribution, default choice
- **Range-Based** — split by value ranges — good for range scans, risk of hot spots
- **Directory-Based** — lookup table maps keys to shards — maximum flexibility

### Challenges
- **Hot Spots** — one shard gets more traffic than others (celebrity problem)
- **Cross-Shard Queries** — queries spanning multiple shards are expensive
- **Consistency** — transactions across shards require sagas or 2PC
- **Rebalancing** — adding shards means moving data

## Real-World Examples

| System | Sharding Approach |
|--------|------------------|
| Cassandra | Consistent hashing with virtual nodes |
| DynamoDB | Hash-based partitioning on partition key |
| MongoDB | Range-based chunks with hashed shard key option |
| Vitess | Sharding layer for MySQL with online resharding |

## License

Educational content — feel free to use and modify for learning purposes.
