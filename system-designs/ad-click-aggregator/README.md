# Ad Click Aggregator

📖 **Source**: [Hello Interview – Ad Click Aggregator](https://www.hellointerview.com/learn/system-design/problem-breakdowns/ad-click-aggregator)

## Overview

An Ad Click Aggregator collects billions of ad-click events and turns them into queryable metrics so advertisers can see how their campaigns are performing — in near real-time.

This is a classic **"Scaling Writes"** problem. At peak we handle **10 000 clicks per second**; the entire architecture (Kafka buffering, sliding-window aggregation, Redis deduplication) is driven by the need to absorb that write pressure without losing a single click.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Click Event Ingestion | Produce & consume click events through Kafka, store in Postgres |
| 2 | Real-Time Aggregation with Sliding Windows | Tumbling & sliding windows, event-time vs processing-time |
| 3 | Deduplication & Fraud Detection | Impression IDs, HMAC signing, Redis-based dedup, anomaly detection |

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
cd system-designs/ad-click-aggregator

# Start PostgreSQL + Redis + Kafka + Visualization Tools
docker-compose up -d

# Create virtual environment and install dependencies
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Register Jupyter kernel
python -m ipykernel install --user --name=adclick --display-name="Ad Click Aggregator (Python)"

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
- **Sliding Windows** — tumbling (fixed) vs sliding (overlapping) time windows
- **Event-Time vs Processing-Time** — why the distinction matters for accuracy

### Deduplication & Fraud Prevention
- **Impression IDs** — unique per ad-show to prevent double-counting
- **HMAC Signing** — cryptographic proof that an impression ID is genuine
- **Redis Dedup Cache** — fast O(1) lookup to reject duplicates before Kafka

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

## License

Educational content — feel free to use and modify for learning purposes.
