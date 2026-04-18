# Online Auction

📖 **Source**: [Hello Interview – Online Auction](https://www.hellointerview.com/learn/system-design/problem-breakdowns/online-auction)

## Overview

An online auction service lets users list items for sale while others compete to purchase them by placing increasingly higher bids until the auction ends, with the highest bidder winning the item.

This sounds simple, but the interesting challenges are all about **concurrency**, **consistency**, and **real-time updates**:

- What happens when two people bid at the exact same time?
- How do you make sure every user sees the same "current highest bid"?
- How do you push bid updates to watchers instantly?

This lab lets you break these problems with real code, then fix them step by step.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Bid Processing & Concurrency | Race conditions, row locking, optimistic concurrency control, Redis atomic operations |
| 2 | Auction Lifecycle Management | Creating auctions, state machines, ending auctions, fault tolerance |
| 3 | Real-Time Bid Notifications | Polling vs push, Redis Pub/Sub, building a live notification system |

## Key Concepts Covered

### Functional Requirements
- Users can **post an item** for auction with a starting price and end date
- Users can **place a bid** (accepted only if higher than the current highest bid)
- Users can **view an auction** including the current highest bid

### Non-Functional Requirements
- **Strong consistency** for bids — all users see the same highest bid
- **Fault tolerance** — no bids can be lost
- **Real-time updates** — current highest bid displayed live
- **Scalability** — support millions of concurrent auctions

### Core Entities
- **User** — someone who creates auctions or places bids
- **Item** — the thing being auctioned (separated from Auction so items can be relisted)
- **Auction** — has a start price, end date, and tracks the current highest bid
- **Bid** — a full audit trail of every bid placed (never delete bid history!)

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd system-designs/online-auction

# Start PostgreSQL + Redis + Visualization Tools
docker-compose up -d

# Install dependencies
uv sync

# Register Jupyter kernel
uv run python -m ipykernel install --user --name=online-auction --display-name="Online Auction (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `auction_demo`
- **Use for**: Watch bid records appear, inspect auction state, observe locking behavior

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch Pub/Sub channels, inspect cached max bids, monitor Lua script execution

## Architecture Highlights

### Why Separate Bidding from Auction Management?
- **Independent scaling** — bidding traffic is ~100× higher than auction creation
- **Isolation** — bidding has complex concurrency logic
- **Performance** — optimize bidding for high-throughput writes separately

### Why Keep Full Bid History?
Overwriting a `max_bid` field destroys data. You **must** keep every bid for:
- Auditing disputes ("I bid $500, why didn't I win?")
- Fraud detection (suspicious bidding patterns)
- Analytics (bidding behavior, pricing trends)

### Why Store max_bid on the Auction Row?
The `auctions.max_bid_amount` column is a **denormalized cache**. Instead of running `SELECT MAX(amount) FROM bids WHERE auction_id = ?` on every read, we maintain the max directly on the auction row. This gives us:
- O(1) reads for the current highest bid
- A single row to lock for concurrency control (instead of locking all bid rows)

## Real-World Scale

| Metric | Value |
|--------|-------|
| Concurrent auctions | 10M |
| Bids per auction | ~100 |
| Peak bid throughput | ~15K bids/second |
| Storage per year | ~25 TB |

## License

Educational content — feel free to use and modify for learning purposes.
