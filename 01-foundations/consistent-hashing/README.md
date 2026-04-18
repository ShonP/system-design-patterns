# Consistent Hashing

## Overview

Imagine you have 3 database servers and thousands of keys to store. How do you decide which server holds which key? The simplest approach — `hash(key) % num_servers` — works great… until you add or remove a server. Suddenly, **almost every key** maps to a different server, causing massive data movement.

**Consistent hashing** solves this by arranging servers on a virtual ring. When a server is added or removed, only a small fraction of keys need to move. This is the algorithm behind systems like DynamoDB, Cassandra, and content delivery networks.

```
    Simple Modulo Hashing          Consistent Hash Ring
    ─────────────────────          ─────────────────────
    hash(key) % N                       ╭───────╮
    Add a server → ~75% keys move      S1       S2
    Remove a server → ~67% move    ╭───╯         ╰───╮
                                   │    keys move    │
                                   │    clockwise →  │
                                   ╰───╮         ╭───╯
                                       S3       S4
                                        ╰───────╯
                                   Add a server → only ~20% keys move!
```

## Notebooks

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | **Naive Hashing Problems** | BAD: modulo hashing breaks on resize · BETTER: simple hash ring · BEST: virtual nodes |
| 2 | **Building a Hash Ring** | Build a consistent hash ring from scratch in Python, visualize key distribution |
| 3 | **Consistent Hashing in Practice** | Real-world usage: Redis Cluster, DynamoDB, Cassandra partitioning |
| 4 | **Beyond the Basics** | Replication on the ring, weighted nodes, rendezvous hashing (HRW), hot-key pitfalls |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic Python knowledge (functions, classes, dictionaries)

## Quick Start

```bash
# 1. Start the Redis nodes
docker compose up -d

# Install dependencies
uv sync

# 3. Register the kernel for Jupyter
uv run python -m ipykernel install --user --name consistent-hashing --display-name "Consistent Hashing (.venv)"

# 4. Open notebooks in VS Code or Jupyter
#    In VS Code: select the "Consistent Hashing (.venv)" kernel (top-right of notebook)
#    If the kernel doesn't appear, reload VS Code (Cmd+Shift+P → "Reload Window")
```

## Visualization Tools

| Tool | URL | Purpose |
|------|-----|---------|
| RedisInsight | [localhost:5541](http://localhost:5541) | Inspect keys across all 3 Redis nodes |

> **Tip:** In RedisInsight, add each Redis node manually:
> - Node 1: `host.docker.internal:6380`
> - Node 2: `host.docker.internal:6381`
> - Node 3: `host.docker.internal:6382`

## Key Concepts Covered

- **Modulo hashing** — simple but breaks when cluster size changes
- **Hash ring** — circular key space minimizes data movement
- **Virtual nodes (vnodes)** — spread load evenly across physical nodes
- **Key redistribution** — measuring how many keys move during changes
- **Replication on the ring** — store each key on N distinct physical nodes for fault tolerance
- **Weighted nodes** — give bigger servers proportionally more vnodes
- **Rendezvous hashing (HRW)** — a simpler ring-free alternative used by CDNs and load balancers
- **Hot-key problem** — what hashing *cannot* solve, and the techniques that can
- **Real-world implementations** — Redis Cluster hash slots, DynamoDB, Cassandra

## Real-World Examples

| System | How It Uses Hashing | Why It Matters |
|--------|-------------------|----------------|
| **Redis Cluster** | CRC16 → 16,384 fixed hash slots | Simple slot-to-node mapping, easy rebalancing |
| **DynamoDB** | Consistent hashing + virtual nodes | Automatic partition placement across AZs |
| **Cassandra** | Token ring with vnodes | Each node owns multiple token ranges |
| **CDNs (Akamai)** | Consistent hashing for cache routing | Determines which edge server caches content |

## Cleanup

```bash
docker compose down
```
