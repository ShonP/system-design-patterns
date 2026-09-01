# Ad Click Aggregator

📖 **Source**: [Hello Interview – Ad Click Aggregator](https://www.hellointerview.com/learn/system-design/problem-breakdowns/ad-click-aggregator)

## Overview

An Ad Click Aggregator collects billions of ad-click events and turns them into queryable metrics so advertisers can see how their campaigns are performing — in near real-time.

This is a classic **"Scaling Writes"** problem. At peak we handle **10 000 clicks per second**; the entire architecture (Kafka buffering, sliding-window aggregation, Redis deduplication) is driven by the need to absorb that write pressure without losing a single click.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Click Event Ingestion | Produce & consume click events through Kafka, store in Postgres, **hot-shard mitigation** for viral ads |
| 2 | Real-Time Aggregation with Sliding Windows | Tumbling & **sliding** windows, half-open boundaries, event-time vs processing-time, **watermarks & late-event drops**, **exactly-once counting via idempotency keys**, **reconciliation (Lambda architecture)** |
| 3 | Deduplication & Fraud Detection | Impression IDs, HMAC signing, Redis-based dedup, **fixed vs sliding-window rate limiting**, anomaly detection |

## Architecture at a Glance

```
User clicks ad
      │
      ▼
┌──────────────┐      ┌────────────┐      ┌─────────────────┐
│ Click        │─────▶│   Kafka    │─────▶│  Aggregation    │
│ Processor    │      │  (buffer)  │      │  Consumer       │
└──────────────┘      └────────────┘      └────────┬────────┘
      │  dedup check                               │
      ▼                                            ▼
┌──────────────┐                          ┌─────────────────┐
│    Redis     │                          │   PostgreSQL    │
│  (dedup +    │                          │  (raw events +  │
│   cache)     │                          │   aggregates)   │
└──────────────┘                          └─────────────────┘
```

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL and message queues

## Quick Start

```bash
# Navigate to the lab directory
cd 06-system-designs/ad-click-aggregator

# Start PostgreSQL + Redis + Kafka + Visualization Tools
docker compose up -d

# Install dependencies
uv sync

# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `adclick_demo`
- **Use for**: Browse raw click events, see aggregated metrics

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch deduplication keys, see impression IDs

### Kafka UI
- **URL**: http://localhost:8081
- **Use for**: See topics, partitions, messages flowing through the click stream

## Key Concepts Covered

### System Design Patterns
- **Scaling Writes** — buffering with Kafka, partitioning by ad_id
- **Pre-Aggregation** — trade storage for query speed
- **Lambda Architecture** — speed layer (streaming) + batch layer (reconciliation)

### Data Pipeline
- **Event Ingestion** — Kafka as a durable, partitioned write buffer
- **Stream Processing** — consuming events in real-time with windowed aggregation
- **Sliding Windows** — tumbling (fixed) vs sliding (overlapping) time windows, and why
  `RANGE ... INTERVAL` beats `ROWS` once a minute has zero clicks
- **Event-Time vs Processing-Time** — why the distinction matters for accuracy
- **Watermarks** — how a stream decides a window is closed, and what it costs when it is wrong
- **Exactly-Once Counting** — at-least-once delivery + an additive UPSERT double-bills the
  advertiser; an idempotency key written in the same transaction is the fix

### Deduplication & Fraud Prevention
- **Impression IDs** — unique per ad-show to prevent double-counting
- **HMAC Signing** — cryptographic proof that an impression ID is genuine
- **Redis Dedup Cache** — fast O(1) lookup to reject duplicates before Kafka
- **Rate Limiting** — a fixed-window counter leaks 2x the limit across a bucket boundary;
  a sliding-window log does not

### Scaling Deep Dives
- **Hot Shard Mitigation** — appending random suffixes to popular ad partition keys
- **Fault Tolerance** — Kafka retention + consumer replay for zero data loss
- **Reconciliation** — periodic batch jobs to verify streaming accuracy

## Real-World Examples

| System | Why This Pattern Matters |
|--------|------------------------|
| Facebook Ads | Billions of impressions/day, real-time spend tracking |
| Google Ads | Click fraud costs advertisers $100B+/year |
| Amazon Ads | Millisecond bidding needs instant click counts |
| TikTok Ads | Viral content causes extreme hot-shard spikes |

## What This Lab Deliberately Does *Not* Do

This is a teaching lab, not a production pipeline. Where the toy version differs from
the real system, the notebooks say so — but in summary:

- **No stream processor.** Windowing, watermarks and state live in Python dictionaries.
  Flink/Spark do this with checkpointed, distributed state and a two-phase-commit sink.
- **`unique_users` is not a distinct count.** Per-window unique counts are added together,
  so a user active in two minutes is counted twice. Real systems merge HyperLogLog sketches.
- **Consumer offsets are never committed.** Each notebook run reads from the start of the
  topic with a fresh consumer group, which is what makes the replay demo easy to stage —
  and is not how you would run this.
- **Reconciliation re-reads the whole table.** A real job is incremental, writes to a
  corrected copy rather than mutating rows advertisers are reading, and alerts on drift
  instead of silently repairing it.
- **Single broker, single partition leader, no replication.** Nothing here survives a
  node loss.

## License

Educational content — feel free to use and modify for learning purposes.
