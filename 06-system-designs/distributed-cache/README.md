# Distributed Cache

📖 **Source**: [Hello Interview – Distributed Cache](https://www.hellointerview.com/learn/system-design/problem-breakdowns/distributed-cache)

## Overview

A single-node cache (like Redis on one server) is fast, but it can't hold 1 TB of data or survive a server crash. A **distributed cache** spreads data across multiple machines so you can store more, serve more requests, and keep running when nodes fail.

The hard part isn't the cache itself — it's deciding **which node owns which key**, keeping data **consistent** across replicas, and **rebalancing** gracefully when nodes join or leave.

This lab gives you three Redis nodes in Docker and Python notebooks that let you build partitioning, coherence, and routing logic from scratch.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Cache Partitioning Strategies | Modulo hashing, range partitioning, why naive approaches break on resize |
| 2 | Cache Coherence & Invalidation | Replication, write propagation, invalidation across a multi-node cluster |
| 3 | Consistent Hashing for Cache Routing | Hash rings, virtual nodes, minimal key movement on scale-up/down |
| 4 | Cache Patterns & Stampede Protection | Cache-aside, read-through, write-through, write-behind, single-flight locks, TTL jitter |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose

## Quick Start

```bash
# Navigate to the lab directory
cd 06-system-designs/distributed-cache

# Start 3 Redis nodes + RedisInsight
docker compose up -d

# Install dependencies
uv sync

# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Add each Redis node:
  - Node 1 → Host `redis-node-1`, Port `6379` (mapped to `localhost:6381`)
  - Node 2 → Host `redis-node-2`, Port `6379` (mapped to `localhost:6382`)
  - Node 3 → Host `redis-node-3`, Port `6379` (mapped to `localhost:6383`)
- **Use for**: Watch how keys land on different nodes, monitor TTLs, compare key counts across shards

## Key Concepts Covered

### Partitioning (Sharding)
- **Modulo Hashing** — `hash(key) % N` — simple but painful on resize
- **Range Partitioning** — key ranges assigned to nodes — easy hot spots
- **Consistent Hashing** — hash ring with virtual nodes — the industry standard

### Cache Coherence
- **Synchronous Replication** — strong consistency, higher latency
- **Asynchronous Replication** — eventual consistency, lower latency
- **Invalidation Strategies** — write-invalidate vs write-update across replicas

### Consistent Hashing
- **Hash Ring** — nodes and keys mapped to the same circular space
- **Virtual Nodes** — multiple positions per physical node for better balance
- **Minimal Disruption** — only K/N keys move when a node is added or removed
- **What the toy ring omits** — no replication, no capacity weighting, no membership protocol; imbalance shrinks like 1/√(vnodes) and never reaches zero

### Hot Keys
- **Read-heavy hot keys** — replicate to spread load
- **Write-heavy hot keys** — shard the key with random suffixes

### Cache Access Patterns
- **Cache-aside (lazy loading)** — app checks cache, loads from DB on miss
- **Read-through** — cache wrapper transparently loads from DB on miss
- **Write-through** — writes go to cache and DB synchronously
- **Write-behind** — writes hit cache first, DB flush happens asynchronously

### Stampede Protection
- **Thundering herd (one key)** — when a hot key expires, N concurrent misses slam the DB
- **Single-flight with Redis lock** — `SET NX EX` + token + Lua release so only one worker recomputes
- **Mass expiry (many keys)** — a cold start warms the whole working set with the same TTL, so it all expires together, forever
- **TTL jitter** — randomise each TTL by ±10% so expiries smear out; the lock cannot help here
- **Negative caching** — store a sentinel for "not found" to avoid repeated DB misses

## Real-World Examples

| System | Why Distributed Caching Matters |
|--------|-------------------------------|
| Amazon | Product pages cached across hundreds of nodes worldwide |
| Twitter | Celebrity profiles replicated to handle viral traffic spikes |
| Discord | Channel metadata partitioned across cache shards by guild |
| Netflix | Video metadata cached globally for sub-millisecond lookups |

## License

Educational content — feel free to use and modify for learning purposes.
