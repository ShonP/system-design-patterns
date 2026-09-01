# Scaling Writes Pattern

📈 **Scaling Writes** addresses the challenge of handling high-volume write operations when a single database or server becomes the bottleneck. As your application grows from hundreds to millions of writes per second, individual components hit hard limits on disk I/O, CPU, and network bandwidth.

## Overview

Write scaling isn't only about throwing more hardware at the problem - there are architectural choices that dramatically improve your system's ability to scale. This pattern covers strategies from database optimization to hierarchical aggregation.

## The Challenge

Many system design problems start with modest scaling requirements before the interviewer asks: "how does it scale?" While you might be familiar with read scaling (replicas, caching), write scaling is often a bigger challenge.

```
Write Bottlenecks:
────────────────────────────────────────────────────────────────────
Problem                     Impact                    Solution
────────────────────────────────────────────────────────────────────
Disk I/O saturation        Writes queue up           SSDs, batching
CPU at 100%                Transactions timeout      Vertical scale
Single DB instance         Can't add capacity        Sharding
Bursty traffic             System crashes            Queues, load shed
Hot partitions             One shard overloaded      Key distribution
────────────────────────────────────────────────────────────────────
```

## Notebooks in This Series

### Part 1: Understanding Write Bottlenecks
- Read vs write characteristics
- Measuring write throughput
- Identifying bottlenecks

### Part 2: Database Optimization for Writes
- Write-optimized databases (Cassandra, time-series)
- LSM vs B-tree **write amplification**, with the arithmetic
- Reducing index overhead (measured, server-side)
- Write-ahead log tuning and `UNLOGGED` tables

### Part 3: Sharding and Partitioning
- Horizontal sharding strategies
- Choosing partition keys, and the **imbalance factor** that scores them
- Monotonically increasing keys: the hot shard that hides in a backfill
- Why cross-shard transactions are designed away rather than paid for
- Consistent hashing and PostgreSQL declarative partitioning
- Vertical partitioning

### Part 4: Queues and Load Shedding
- Async write patterns
- Burst absorption
- Graceful degradation (and which priority tier you start eating)
- Dead-letter queues, backpressure
- At-most-once vs at-least-once: what a crash mid-processing loses

### Part 5: Batching and Aggregation
- Write batching strategies
- The latency side of the trade: staleness measured against flush interval
- Hierarchical aggregation
- Fan-in/fan-out patterns

### Part 6: Hot Keys and Advanced Patterns
- Detecting hot keys
- Fixed-K and rate-driven dynamic key splitting
- Resharding without downtime (double-write → backfill → verify → cut over)

## Prerequisites

- Python 3.10+
- [uv](https://docs.astral.sh/uv/) (fast Python package manager)
- Docker & Docker Compose
- Basic understanding of databases

## Quick Start

```bash
# Navigate to the pattern directory
cd 04-patterns/scaling-writes

# Start PostgreSQL + Redis + Visualization Tools
docker compose up -d

# Install dependencies
uv sync

# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/

# Start with the first notebook!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System: `PostgreSQL`, Server: `postgres`, Username: `demo`, Password: `demo`, Database: `writes_demo`
- **Use for**: Watch write throughput, table sizes, index overhead

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host: `redis`, Port: `6379`
- **Use for**: Watch queue lengths, batch operations, hot key detection

## Real-World Applications

| Application | Challenge | Solution |
|-------------|-----------|----------|
| Twitter | Celebrity tweets = hot keys | Key splitting, fan-out |
| Uber | Location updates at scale | Load shedding, batching |
| YouTube | View count updates | Hierarchical aggregation |
| Instagram | Like counts on viral posts | Sharded counters |
| Strava | GPS point ingestion | Time-series DB, batching |

## Decision Flowchart

```
                    ┌─────────────────────────────┐
                    │ Are writes the bottleneck?  │
                    │ (Do the math!)              │
                    └─────────────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
                  Yes                       No
                    │                       │
                    ▼                       ▼
            ┌───────────────┐      ┌───────────────┐
            │ Can vertical  │      │ Focus on      │
            │ scaling help? │      │ other issues  │
            └───────────────┘      └───────────────┘
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
       Yes                      No
        │                       │
        ▼                       ▼
┌───────────────┐      ┌───────────────┐
│ Upgrade HW,   │      │ Is traffic    │
│ optimize DB   │      │ bursty?       │
└───────────────┘      └───────────────┘
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
                   Yes                      No
                    │                       │
                    ▼                       ▼
            ┌───────────────┐      ┌───────────────┐
            │ Queues +      │      │ Shard by      │
            │ Load shedding │      │ good key      │
            └───────────────┘      └───────────────┘
```

## Key Takeaways

1. **Do the math first** - Verify writes are actually the bottleneck
2. **Exhaust vertical scaling** - Modern hardware is powerful
3. **Choose partition keys wisely** - Bad keys create hot spots, and the worst
   ones (monotonic keys) look perfectly balanced until live traffic arrives
4. **Queues smooth bursts** - But don't mask underlying problems, and an
   unbounded queue is a bug
5. **Batch aggressively** - Reduce per-write overhead, and price the staleness
   it costs you
6. **Resharding is never free** - which is why the shard key is a day-one decision

## The Four Strategies

```
┌─────────────────────────────────────────────────────────────────┐
│  1. Vertical Scaling      → Better hardware, DB optimization    │
│  2. Sharding              → Spread load across servers          │
│  3. Queues/Load Shedding  → Handle bursts gracefully           │
│  4. Batching/Aggregation  → Reduce write frequency             │
└─────────────────────────────────────────────────────────────────┘
```

## License

Educational content - feel free to use and modify for learning purposes.
