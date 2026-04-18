# Cassandra Deep Dive

📖 **Source**: [Hello Interview – Cassandra Deep Dive for System Design Interviews](https://www.hellointerview.com/learn/system-design/deep-dives/cassandra)

## Overview

Apache Cassandra is an open-source, distributed NoSQL database designed for massive scalability and high availability. It combines ideas from Amazon's Dynamo (consistent hashing, replication) and Google's Bigtable (column-oriented storage, LSM trees) to handle huge data volumes with fast writes and tunable consistency.

Originally built by Facebook for inbox search, Cassandra is now used by Discord, Netflix, Apple, and many others. This lab lets you run a real 3-node Cassandra cluster on your laptop and explore its core concepts hands-on.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Data Modeling with Partition Keys | How partition keys determine data placement, query-driven modeling, the Discord messages example |
| 2 | Wide Rows and Clustering Columns | Clustering keys, sort order, wide rows, the Ticketmaster example |
| 3 | Replication and Consistency Levels | Replication strategies, consistency levels (ONE, QUORUM, ALL), CAP trade-offs |
| 4 | Compaction Strategies | LSM trees, memtables, SSTables, compaction strategies, tombstones |
| 5 | LWT, TTL & Anti-Patterns | Lightweight transactions, TTL, counters, batches, secondary indexes, paging, production tuning |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- No prior Cassandra experience needed — we start from scratch

## Quick Start

```bash
# Navigate to the lab directory
cd deep-dives/cassandra

# Start the 3-node Cassandra cluster (first start takes ~2 minutes)
docker-compose up -d

# Wait for node1 to be healthy before running notebooks
docker-compose exec cassandra-node1 cqlsh -e "DESCRIBE CLUSTER"

# Install dependencies
uv sync

# Register Jupyter kernel
uv run python -m ipykernel install --user --name=cassandra --display-name="Cassandra (Python)"

# Open the first notebook and start learning!
```

> **Note**: The 3-node cluster needs ~2 GB of RAM. If your machine is constrained, you can comment out `cassandra-node3` in `docker-compose.yml` — the notebooks still work with 2 nodes.

## Cluster Architecture

```
┌─────────────────────────────────────────────────┐
│                 demo-cluster                     │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │  node1   │  │  node2   │  │  node3   │       │
│  │ (seed)   │  │          │  │          │       │
│  │ rack1    │  │ rack2    │  │ rack3    │       │
│  │ :9042    │  │          │  │          │       │
│  └──────────┘  └──────────┘  └──────────┘       │
│                                                  │
│  All nodes in datacenter: dc1                    │
└─────────────────────────────────────────────────┘
```

Your Python code connects to `localhost:9042` (node1). The Cassandra driver automatically discovers the other nodes via the gossip protocol.

## Key Concepts Covered

### Data Model
- **Keyspace** — top-level container (like a database in PostgreSQL)
- **Table** — organizes data into rows with a schema
- **Partition Key** — determines which node stores a row
- **Clustering Key** — determines sort order within a partition

### Architecture
- **Consistent Hashing** — distributes data evenly across nodes using a token ring
- **Virtual Nodes (vnodes)** — each physical node owns multiple positions on the ring
- **Gossip Protocol** — peer-to-peer protocol for sharing cluster state
- **Hinted Handoff** — temporarily stores writes for offline nodes

### Storage Engine (LSM Tree)
- **Commit Log** — write-ahead log for durability
- **Memtable** — in-memory sorted buffer for recent writes
- **SSTable** — immutable on-disk files flushed from memtables
- **Compaction** — merges SSTables to reclaim space and remove tombstones

### Consistency
- **Tunable Consistency** — choose between ONE, QUORUM, ALL per query
- **Eventual Consistency** — all replicas converge given enough time
- **CAP Theorem** — Cassandra favors Availability and Partition tolerance (AP)
- **Lightweight Transactions (LWT)** — Paxos-based compare-and-set for true uniqueness
- **TTL** — rows can auto-expire after a fixed number of seconds

### Anti-Patterns to Avoid
- `ALLOW FILTERING` in production code paths
- Large multi-partition `BATCH` statements
- Secondary indexes on high-traffic columns (build a second table instead)
- Unbounded partition growth — always bucket partitions that can grow forever

## Real-World Examples

| System | Why Cassandra |
|--------|---------------|
| Discord | Stores billions of messages with time-bucketed partitions |
| Netflix | Stores viewing history, bookmarks, and user activity at massive scale |
| Apple | Powers 400+ PB of data across 160,000+ nodes |
| Ticketmaster | Serves ticket availability for high-demand events |

## License

Educational content — feel free to use and modify for learning purposes.
