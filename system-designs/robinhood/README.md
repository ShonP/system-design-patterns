# Robinhood — Stock Brokerage System Design Lab

📖 **Source**: [Hello Interview – Robinhood](https://www.hellointerview.com/learn/system-design/problem-breakdowns/robinhood)

## Overview

Robinhood is a commission-free stock brokerage that lets users view live market prices and place trades. It is **not** an exchange — it routes orders through external market makers and earns revenue via payment for order flow.

This lab walks you through the three core pillars of a brokerage system: **order management**, **portfolio tracking**, and **real-time market data** — all with runnable code against real infrastructure.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Order Matching Engine | Order types (market/limit), order book mechanics, brokerage order lifecycle, consistency & failure handling |
| 2 | Portfolio & Position Tracking | Positions table design, average cost, realized/unrealized P&L, cache-aside with Redis |
| 3 | Market Data Streaming | Kafka trade feed, price processor, Redis pub/sub fan-out, SSE vs WebSockets |

## Architecture

```
  Exchange            Our Backend                                      User
  ────────           ────────────                                     ────

  Trade Feed ──────► Kafka ──────► Price       Redis Pub/Sub ──────► Symbol
  (external)         topic:        Processor   (fan-out)              Service ──► SSE ──► App
                     trades        (consumer)       │
                                       │            │
                                       ▼            ▼
                                   Postgres      Redis Cache
                                   (orders,      (live prices)
                                    positions,
                                    prices)
```

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd system-designs/robinhood

# Start PostgreSQL + Redis + Kafka + Visualization Tools
docker-compose up -d

# Create virtual environment and install dependencies
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Register Jupyter kernel
python -m ipykernel install --user --name=robinhood --display-name="Robinhood (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `robinhood_demo`
- **Use for**: Inspect orders, positions, price history, and user balances

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch price cache keys, monitor pub/sub channels, see portfolio cache

## Key Concepts Covered

### Core Entities
- **User** — a customer of the brokerage
- **Symbol** — a tradeable stock (e.g. AAPL, META)
- **Order** — a buy/sell instruction from a user (market or limit)
- **Trade** — a filled order (executed at a specific price)
- **Position** — how many shares a user holds of a given symbol

### Order Management
- **Market orders** execute immediately at best available price
- **Limit orders** wait until a target price is reached
- **Order lifecycle**: `pending → submitted → filled / cancelled / failed`
- **Consistency**: save to DB before submitting to exchange (crash recovery)
- **Cleanup jobs** reconcile stuck orders for eventual consistency

### Portfolio Tracking
- **Positions table** for O(1) portfolio lookups (not scanning all trades)
- **Average cost** recalculated on each buy
- **Unrealized P&L** = (market price − avg cost) × quantity
- **Realized P&L** = (sell price − avg cost) × quantity
- **ACID transactions** for atomic balance + position updates

### Real-Time Market Data
- **Kafka** buffers the exchange trade feed (durable, replayable)
- **Price Processor** consumes from Kafka → updates Postgres + Redis
- **Redis Pub/Sub** fans out price updates to connected symbol servers
- **SSE (Server-Sent Events)** pushes prices to clients (better than polling)
- **Redis Cache** stores latest prices for instant initial page loads

### Non-Functional Requirements
- **High consistency** for orders (ACID, reconciliation)
- **Low latency** for price updates (< 200 ms goal)
- **Minimal exchange connections** (proxy via gateway, not per-client)
- **Horizontal scaling** via Kafka partitioning and stateless services

## Real-World Design Decisions

| Decision | Why |
|----------|-----|
| Cents, not dollars | Integers avoid floating-point precision bugs — critical for finance |
| Save order before exchange call | If the system crashes after exchange accepts, we still have a record |
| Kafka before Redis | Kafka is durable; Redis pub/sub is fire-and-forget. Kafka handles replays |
| SSE over WebSockets | Price data is one-directional (server → client). SSE is simpler |
| Positions table (materialized) | O(1) lookups vs O(n) trade scanning for portfolio views |
| Redis pub/sub per symbol | Servers subscribe only to symbols their users watch |

## License

Educational content — feel free to use and modify for learning purposes.
