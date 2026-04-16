# DynamoDB

📖 **Source**: [Hello Interview – DynamoDB Deep Dive for System Design Interviews](https://www.hellointerview.com/learn/system-design/deep-dives/dynamodb)

## Overview

DynamoDB is a fully-managed, highly scalable, key-value NoSQL database provided by AWS. It automatically handles hardware provisioning, scaling, and replication so you can focus on your application.

In this lab you'll work with **DynamoDB Local** — an offline version of DynamoDB that runs in Docker — so you can experiment with every feature without an AWS account or any cloud costs.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Partition Keys and Sort Keys | How DynamoDB organizes data, choosing keys, composite primary keys |
| 2 | Secondary Indexes (GSI & LSI) | Querying by non-key attributes, GSI vs LSI trade-offs |
| 3 | Single-Table Design | Modeling multiple entities in one table, access-pattern-driven design |
| 4 | DynamoDB Streams and CDC | Change Data Capture, reacting to data changes in real time |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- No AWS account needed (we use DynamoDB Local)

## Quick Start

```bash
# Navigate to the lab directory
cd deep-dives/dynamodb

# Start DynamoDB Local + Admin GUI
docker-compose up -d

# Install dependencies
uv sync

# Register Jupyter kernel
uv run python -m ipykernel install --user --name=dynamodb --display-name="DynamoDB (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### DynamoDB Admin GUI
- **URL**: http://localhost:8001
- **Use for**: Browse tables, view items, watch data change as you run notebooks

## Key Concepts Covered

### Data Model
- **Tables** — top-level data structure, defined by a primary key
- **Items** — individual records (like rows), up to 400KB each
- **Attributes** — key-value pairs within an item (schema-less, flexible)

### Keys
- **Partition Key** — determines which physical partition stores the item (hash-based)
- **Sort Key** — orders items within a partition (enables range queries)
- **Composite Key** — partition key + sort key together uniquely identify an item

### Secondary Indexes
- **Global Secondary Index (GSI)** — different partition key, separate storage, eventually consistent
- **Local Secondary Index (LSI)** — same partition key, different sort key, supports strong consistency

### Access Patterns
- **Query** — efficient lookup by primary key or index (always prefer this)
- **Scan** — reads every item in the table (expensive, avoid in production)

### Advanced Features
- **DynamoDB Streams** — captures insert/update/delete events for Change Data Capture (CDC)
- **DAX** — in-memory cache for microsecond read latency
- **Global Tables** — multi-region replication
- **Transactions** — ACID operations across up to 100 items

### CAP Theorem Position
- **Eventually consistent reads** (default) — lower latency, 0.5 RCU per 4KB
- **Strongly consistent reads** — routed to leader node, 1 RCU per 4KB

## Real-World Examples

| System | How DynamoDB Helps |
|--------|-------------------|
| Chat App | Partition by chat_id, sort by message_id for chronological retrieval |
| E-commerce | Product catalog with GSI on category for browse pages |
| Gaming | Player profiles with leaderboard GSI on score |
| IoT | Device data partitioned by device_id, sorted by timestamp |

## License

Educational content — feel free to use and modify for learning purposes.
