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
| 1 | Bid Processing & Concurrency | Requirements + capacity estimate, a **demonstrated lost bid**, row locking, **bids accepted after close** and the fix, OCC, Redis atomic CAS |
| 2 | Auction Lifecycle Management | Creating auctions, state machines, ending auctions, fault tolerance |
| 3 | Real-Time Bid Notifications | Polling vs push, Redis Pub/Sub, building a live notification system |
| 4 | Reserve, Increments & Proxy Bidding | Hidden reserve prices, eBay-style bid increment ladders, proxy (automatic) bidding |

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
cd 06-system-designs/online-auction

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

Notebook 1 computes all of these from stated assumptions — run the cell rather
than trusting the table.

| Metric | Value | Where it comes from |
|--------|-------|---------------------|
| Concurrent auctions | 10M | assumption |
| Average auction length | 7 days | assumption |
| Bids per auction | ~100 | assumption |
| Bid throughput | ~1,650/s avg | 10M ÷ 7 days × 100 bids ÷ 86,400 |
| Peak bid throughput | ~16,500/s | ×10, because bids pile up in the final minute (sniping) |
| Auction page reads | ~165,000/s | 100 views per bid — a 100:1 read:write ratio |
| Bid storage | ~10 TB/year | 143M bids/day × 200 B × 365 |
| **Contention on one hot auction row** | ~50 bids/s | The number that actually limits the design — these must serialise |

## License

Educational content — feel free to use and modify for learning purposes.
