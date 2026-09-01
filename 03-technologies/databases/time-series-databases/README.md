# Time-Series Databases

📖 **Source**: [Hello Interview – Time Series Databases for System Design Interviews](https://www.hellointerview.com/learn/system-design/03-technologies/databases/time-series-databases)

## Overview

Time-series databases are purpose-built for workloads where data arrives as a continuous stream of timestamped measurements — think server metrics, IoT sensors, or stock prices. They exploit properties unique to this data (append-only writes, correlated timestamps, low-cardinality tags) to achieve 10–100× better performance than a general-purpose database.

This lab uses **TimescaleDB** — a PostgreSQL extension — so you get the power of a time-series engine with the familiar SQL interface you already know. **Grafana** is included for building dashboards on top of the data.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Time-Series Data Modeling | Hypertables, tags vs. fields, chunk-based partitioning, cardinality explosion, bulk ingest (`INSERT` vs `executemany` vs `COPY`) |
| 2 | Windowed Aggregations | `time_bucket()`, moving averages, percentile detection, multi-host comparison, gap-filling (`locf`/`interpolate`), `first()`/`last()`, rate-of-change with `LAG()` |
| 3 | Retention Policies & Downsampling | Auto-delete old data, continuous aggregates, **native compression** (delta-of-delta + Gorilla), tiered storage strategy |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd 03-technologies/databases/time-series-databases

# Start TimescaleDB + Grafana + Adminer
docker compose up -d

# Install dependencies
uv sync

# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (SQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `timescaledb`, Username `demo`, Password `demo`, Database `tsdb_demo`
- **Use for**: Run SQL queries, explore table schemas, inspect hypertable chunks

### Grafana (Dashboards)
- **URL**: http://localhost:3000
- **Login**: `admin` / `admin`
- **First time setup**: Add a PostgreSQL data source → Host `timescaledb:5432`, Database `tsdb_demo`, User `demo`, Password `demo`
- **Use for**: Build real-time dashboards, visualize time-bucketed data, set up alerts

## Key Concepts Covered

### The Time-Series Data Model
- **Measurements** — like tables (e.g., `cpu_usage`, `memory_usage`)
- **Tags** — indexed metadata for filtering (e.g., `host`, `region`)
- **Fields** — the actual measured values (e.g., `value=45.2`)
- **Timestamps** — when the measurement was taken

### Building Blocks of Time-Series Databases
- **Append-Only Storage** — sequential writes instead of random I/O
- **LSM Trees** — high write throughput by deferring organization to background compaction
- **Delta Encoding** — store differences between values instead of absolute values
- **Time-Based Partitioning** — chunks/shards by time for fast writes, reads, and retention
- **Bloom Filters** — skip irrelevant data files without reading them
- **Downsampling & Rollups** — trade precision for storage efficiency on older data

### Common Pitfalls
- **Cardinality Explosion** — too many unique tag combinations kills memory and performance
- **Over-Indexing** — fields should *not* be indexed; only tags
- **Premature TSDB Adoption** — don't reach for a TSDB when Postgres would work fine

## Real-World Examples

| System | Why TSDBs Matter |
|--------|-----------------|
| Datadog | Billions of metric points per minute from customer infrastructure |
| Prometheus | Pull-based monitoring for Kubernetes clusters |
| IoT Platforms | Millions of sensors emitting readings every second |
| Financial Trading | Tick-by-tick price data for analysis and backtesting |

## Lab Data

The `init.sql` script creates a monitoring scenario:
- **10 hosts** across 2 regions (`us-west`, `us-east`)
- **4 metrics** per host: `cpu_usage`, `memory_usage`, `disk_io`, `network_rx`
- **7 days** of 30-second resolution data (~8M+ rows)
- A plain PostgreSQL table (`metrics_plain`) for performance comparison

## License

Educational content — feel free to use and modify for learning purposes.
