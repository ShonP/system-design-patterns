# Numbers to Know for System Design

📖 **Source**: [Hello Interview – Numbers to Know](https://www.hellointerview.com/learn/system-design/core-concepts/numbers-to-know)

## Overview

One of the biggest giveaways in a system design interview is using **outdated numbers**. Candidates quote memory limits from 2015, storage costs from 2020, and end up over-engineering systems that a single modern server could handle.

This lab teaches you the numbers that actually matter in 2026 — **by measuring them yourself**. You'll benchmark latencies, calculate throughput, and practice back-of-envelope estimation for real systems like Twitter, YouTube, and Uber.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Latency Numbers | Benchmark L1 cache → RAM → SSD → Redis → PostgreSQL. BAD vs GOOD latency-aware design. |
| 2 | Throughput & Capacity | Calculate QPS, storage, bandwidth. BAD (guessing) → BETTER (envelope math) → BEST (measured). |
| 3 | Back-of-Envelope Estimation | Practice estimating capacity for Twitter, YouTube, and Uber step-by-step. |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd 01-foundations/numbers-to-know

# Start PostgreSQL + Redis + Visualization Tools
docker-compose up -d

# Install dependencies
uv sync

# Register Jupyter kernel
uv run python -m ipykernel install --user --name=numbers-to-know --display-name="Numbers to Know (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `numbers_demo`
- **Use for**: Explore benchmark data, run queries, see table sizes

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch keys, monitor throughput, see memory usage

## Key Numbers Cheat Sheet (2026)

### Latency Hierarchy
| Operation | Latency | |
|-----------|---------|--|
| L1 cache reference | ~1 ns | ⚡ |
| L2 cache reference | ~4 ns | ⚡ |
| Main memory (RAM) | ~100 ns | |
| SSD random read | ~16 μs | |
| Read 1 MB from RAM | ~250 μs | |
| Round trip in datacenter | ~500 μs | |
| Read 1 MB from SSD | ~1 ms | |
| HDD disk seek | ~2 ms | |
| Read 1 MB from HDD | ~5 ms | |
| Internet round trip (same continent) | ~50 ms | 🐌 |

### Modern Server Capabilities
| Resource | Typical | Max Available |
|----------|---------|---------------|
| RAM | 256 GB | 24 TB |
| CPU cores | 64 vCPUs | 128+ vCPUs |
| Local SSD | 2 TB | 60 TB |
| Local HDD | — | 336 TB |
| Network | 25 Gbps | 100+ Gbps |

### Quick Math
| Fact | Value |
|------|-------|
| Seconds in a day | 86,400 ≈ ~100K |
| Seconds in a year | ~31.5M ≈ ~30M |
| 1 million requests/day | ~12 QPS |
| 1 billion requests/day | ~12K QPS |
| 1 KB × 1 billion | 1 TB |

## Common Interview Mistakes

1. **Premature sharding** — A single Postgres handles 1+ TB and 10K QPS. Don't shard until you must.
2. **Overestimating latency** — Redis is ~0.5 ms, not "a few seconds". Modern networks are fast.
3. **Using 2015 numbers** — Servers have 512 GB RAM now, not 16 GB. Recalibrate your mental model.
4. **Forgetting to show your math** — Interviewers want to see the calculation, not just the answer.

## License

Educational content — feel free to use and modify for learning purposes.
