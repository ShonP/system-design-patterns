# Metrics Monitoring

📖 **Source**: [Hello Interview – Metrics Monitoring](https://www.hellointerview.com/learn/system-design/problem-breakdowns/metrics-monitoring)

## Overview

A metrics monitoring platform collects performance data (CPU, memory, throughput, latency) from servers and services, stores it as **time-series data**, visualizes it on dashboards, and triggers alerts when thresholds are breached. Think **Datadog**, **Prometheus/Grafana**, or **AWS CloudWatch**.

This lab teaches you the core concepts by building a working monitoring stack from scratch using Prometheus (collection + storage), Grafana (visualization), PostgreSQL (alert rule storage), and Redis (caching query results).

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Metrics Collection & Time-Series Storage | What metrics are, how Prometheus scrapes them, time-series data model |
| 2 | Alerting Rules & Thresholds | How alert rules work, evaluation loops, notification routing |
| 3 | Dashboard Design & Visualization | Building dashboards in Grafana, query optimization, rollups |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of HTTP APIs

## Quick Start

```bash
# Navigate to the lab directory
cd system-designs/metrics-monitoring

# Start PostgreSQL + Redis + Prometheus + Grafana + Visualization Tools
docker-compose up -d

# Create virtual environment and install dependencies
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Register Jupyter kernel
python -m ipykernel install --user --name=metrics-monitoring --display-name="Metrics Monitoring (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Prometheus (Time-Series Database + Query Engine)
- **URL**: http://localhost:9090
- **Use for**: Run PromQL queries, explore collected metrics, check scrape targets

### Grafana (Dashboard & Visualization)
- **URL**: http://localhost:3000
- **Login**: Username `admin`, Password `admin`
- **Use for**: Build dashboards, create panels, visualize time-series data

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `metrics_demo`
- **Use for**: Browse alert rules, notification channels, alert history

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: See cached query results, monitor TTLs

## Key Concepts Covered

### Core Entities
- **Metric**: A named measurement (e.g., `cpu_usage`) with labels and a value at a point in time
- **Label**: A key-value pair (e.g., `host="server-1"`) for slicing and filtering
- **Series**: A unique combination of metric name + labels tracked over time
- **Alert Rule**: A condition (query + threshold + duration) that triggers notifications
- **Dashboard**: A collection of panels, each displaying a query result as a chart

### Data Flow
```
Servers → Agent/Collector → Kafka → Ingestion Service → Time-Series DB
                                                              ↓
                                    Dashboard ← Query Service ← Cache (Redis)
                                                              ↓
                              Notification Service ← Alert Evaluator
```

### Architecture Decisions
- **Push vs Pull**: Prometheus uses pull (scrapes endpoints); Datadog uses push (agents send data)
- **Time-Series DB**: Specialized storage optimized for append-only writes and time-range queries
- **Rollups**: Pre-computed aggregates (1-min, 1-hour, 1-day) for fast long-range queries
- **Polling Alerts**: Evaluate rules on a schedule — simple and battle-tested (Prometheus approach)
- **Stream Alerts**: Use Flink/Kafka for sub-second detection — complex but faster

### Common Problems
- **Cardinality Explosion**: Too many unique label combinations create millions of series
- **Alert Fatigue**: Too many noisy alerts cause engineers to ignore them
- **Query Performance**: Scanning billions of raw data points for a 30-day dashboard panel

## Real-World Examples

| System | What They Monitor |
|--------|------------------|
| Datadog | Full-stack observability — metrics, logs, traces from any infrastructure |
| Prometheus/Grafana | Open-source standard for Kubernetes and cloud-native monitoring |
| AWS CloudWatch | AWS resource metrics + custom application metrics |
| New Relic | Application performance monitoring (APM) + infrastructure |

## License

Educational content — feel free to use and modify for learning purposes.
