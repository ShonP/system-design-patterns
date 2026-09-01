# Robinhood — Stock Brokerage System Design Lab

📖 **Source**: [Hello Interview – Robinhood](https://www.hellointerview.com/learn/system-design/problem-breakdowns/robinhood)

## Overview

Robinhood is a commission-free stock brokerage that lets users view live market prices and place trades. It is **not** an exchange — it routes orders through external market makers and earns revenue via payment for order flow.

This lab walks you through the three core pillars of a brokerage system: **order management**, **portfolio tracking**, and **real-time market data** — all with runnable code against real infrastructure.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Order Matching Engine | Order types (market/limit), order book mechanics, price-time priority, brokerage order lifecycle, consistency & failure handling |
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
cd 06-system-designs/robinhood

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
- **Market orders** execute immediately at best available price (and never rest on the book)
- **Limit orders** wait until a target price is reached
- **Price-time priority** — best price first, then earliest arrival; a partial fill keeps
  its place at the front of the queue
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
| Order + trade + position + balance in one transaction | An order marked `filled` with no `trades` row behind it is the classic silent money bug |
| Redis pub/sub per symbol | Servers subscribe only to symbols their users watch |

## Honest Limits of This Lab

The point of the lab is the mechanics, not fidelity. Each notebook ends with its own
"What This Toy Does NOT Do" list; the headline omissions are:

- **The matching engine is single-threaded, single-symbol and in memory.** No self-trade
  prevention, no stop/IOC/FOK/iceberg orders, no auctions, halts or tick-size rules. A real
  engine is a replicated state machine fed by a sequenced input log.
- **No settlement or buying power.** Cash moves the instant a trade is processed; there is no
  T+1, no settled-vs-unsettled distinction, and no margin.
- **One blended average cost per symbol.** Real tax reporting needs lot-level cost basis
  (FIFO/LIFO/specific-ID), and corporate actions rewrite it.
- **No short positions** — quantity floors at zero.
- **Redis pub/sub has no backpressure.** A slow subscriber is silently disconnected and loses
  data. Notebook 3 spells out why the fix is conflation, not queueing — but it does not
  implement it, and 25 trades is far too small to surface the problem.
- **No SSE server is actually built.** The pipeline stops at the Redis subscriber.

## License

Educational content — feel free to use and modify for learning purposes.
