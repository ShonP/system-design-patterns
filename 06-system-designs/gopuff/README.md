# Design a Local Delivery Service like Gopuff

📖 **Source**: [Hello Interview – Gopuff System Design](https://www.hellointerview.com/learn/system-design/problem-breakdowns/gopuff)

## Overview

Gopuff delivers convenience-store items in under 30 minutes from 500+ **micro-fulfillment centers** (MFCs). Unlike DoorDash or Uber Eats — which pick up from third-party stores — Gopuff owns the inventory sitting in its own small warehouses spread across a city.

This lab walks you through three core challenges of running a system like Gopuff:

1. **Inventory Management** — How do you track stock across many small warehouses and make sure two customers never buy the same last item?
2. **Delivery Routing & ETA** — How do you find the nearest warehouse and estimate delivery time?
3. **Demand Forecasting & Dynamic Pricing** — How do you predict what people will order and adjust prices in real time?

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Inventory Management Across Micro-Fulfillment Centers | Requirements + capacity estimate, aggregated stock, a **demonstrated oversell** and its `SERIALIZABLE` fix, cache-aside with Redis |
| 2 | Delivery Routing and ETA Estimation | Haversine vs Euclidean, zone-based ETAs, and a real **Redis `GEOSEARCH` spatial index** benchmarked against the linear scan |
| 3 | Demand Forecasting and Dynamic Pricing | Moving-average forecasting, surge pricing tiers, the N+1 query trap, and why you never round before summing |

## Core Entities

```
┌──────────────────────┐      ┌──────────────────────┐
│  Item                │      │  DistributionCenter   │
│  (what you can buy)  │      │  (where stock lives)  │
└──────────┬───────────┘      └──────────┬────────────┘
           │                             │
           │        ┌────────────┐       │
           └────────│  Inventory │───────┘
                    │  (DC has N │
                    │   of item) │
                    └─────┬──────┘
                          │
                    ┌─────┴──────┐
                    │   Order    │
                    │ (customer  │
                    │  purchase) │
                    └────────────┘
```

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd 06-system-designs/gopuff

# Start PostgreSQL + Redis + Visualization Tools
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
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `gopuff`
- **Use for**: Browse tables, run queries, watch inventory change

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch cache keys, monitor TTLs, see what's cached

## Key Concepts Covered

### Inventory Management
- **Aggregated availability** — union stock from all nearby DCs
- **Atomic transactions** — Postgres SERIALIZABLE isolation prevents double-booking
- **Cache-aside pattern** — Redis sits in front of Postgres for fast reads (< 100 ms)
- **Cache invalidation** — expire cache entries when orders change inventory

### Delivery Routing
- **Haversine formula** — find DCs within delivery range on a sphere
- **Zone-based routing** — pre-computed delivery zones per DC
- **ETA estimation** — combine distance, historical times, and traffic factors

### Demand Forecasting & Dynamic Pricing
- **Hourly demand patterns** — peak hours vs off-peak
- **Simple moving average** — predict future demand from recent history
- **Surge pricing** — raise prices when demand outpaces supply
- **Price elasticity** — balance revenue and order volume

## Non-Functional Requirements (from the interview)

| Requirement | Target |
|-------------|--------|
| Availability query latency | < 100 ms |
| Order consistency | Strongly consistent (no double-booking) |
| Scale | 10k DCs, 100k items, 10M orders/day |

## License

Educational content — feel free to use and modify for learning purposes.
