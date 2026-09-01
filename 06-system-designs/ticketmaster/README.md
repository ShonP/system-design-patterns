# Ticketmaster System Design Lab

📖 **Source**: [Hello Interview – Design Ticketmaster](https://www.hellointerview.com/learn/system-design/problem-breakdowns/ticketmaster)

## Overview

Ticketmaster is a ticket booking platform where millions of users compete for a limited number of seats. The core engineering challenge: **how do you let 10 million people try to book the same 20,000 seats without selling any seat twice?**

This lab walks you through the hardest parts of the design — seat locking, flash sales, payment flows, and scaling — with real, runnable code against PostgreSQL and Redis.

## Requirements

### Functional

| # | Requirement |
|---|-------------|
| 1 | Browse events and view a venue's seat map with live availability |
| 2 | Search events by keyword, performer, venue, or date |
| 3 | **Hold** selected seats while the user pays, and release them if they don't |
| 4 | Purchase held seats — payment turns a hold into a permanent sale |
| 5 | Book multiple seats atomically (all or nothing) |

### Non-Functional

| # | Requirement | Target |
|---|-------------|--------|
| 1 | **No double booking** | strong consistency on the seat. This is non-negotiable and shapes the whole design. |
| 2 | **Read-heavy scale** | ~100:1 reads to writes — browsing must not be slowed by booking |
| 3 | **Flash-sale tolerance** | survive 10M users arriving inside one minute without falling over |
| 4 | **Low latency reads** | seat map < 100 ms |
| 5 | **Availability for reads, consistency for writes** | you can serve a slightly stale seat map; you cannot sell a seat twice |

### Out of scope

Dynamic pricing, ticket resale/transfer, fraud and bot detection (a real ticketing
platform spends enormous effort here), and refunds.

---

## Capacity Estimate

Assumptions: **1,000 events on sale**, a large one is **50,000 seats**, a flash sale draws
**10M users in the first minute**, and browsing runs at **100 reads per write**.

**The write path — this is the constrained one**

```
50,000 seats is the entire inventory of one big event.
Even if every seat sells, that is only 50,000 successful writes.

The load is not the successful writes, it is the attempts:
  10M users / 60s = ~167,000 booking attempts/sec at the peak

Little's Law: connections = arrival rate x time held
  167,000/sec x 0.2s per transaction = ~33,000 open connections
  Postgres tops out in the low hundreds.
```

That single number is the entire justification for the waiting queue in Notebook 2 and for
keeping holds out of the database (Notebook 3). You cannot index your way past it — you have
to reduce either the arrival rate or the time in transaction, and the queue does the first
while short transactions + Redis holds do the second.

**The read path**

```
167,000 writes/sec attempted x 100 reads per write ≈ 17M reads/sec at peak

Served from cache, not Postgres:
  seat map for one event ~50,000 seats x ~40 B = 2 MB
  1,000 live events x 2 MB = 2 GB   ← the entire hot dataset fits in RAM
```

The whole seat-map working set is 2 GB. That is why Notebook 4 caches aggressively: the
data is small, the read rate is enormous, and the two facts together make caching the
obvious answer rather than a clever one.

**Holds in Redis**

```
Concurrent holds during a flash sale ≈ seats being checked out at once, say 50,000
  one lock key + one booking key, ~100 B each = ~10 MB
```

Trivially small. The cost of holds is not memory — it is the durability question below.

**Storage (long-term)**

```
1,000 events/day x 50,000 tickets x ~200 B  = 10 GB/day of ticket rows
Bookings are smaller and fewer. Well inside a single Postgres cluster
with partitioning by event date.
```

---

## The Central Design Decision: Where Does a "Hold" Live?

A ticket has exactly **two** states in PostgreSQL: `available` and `sold`. The temporary
held state lives **only in Redis**, as a key with a TTL.

**What this buys**

- Transactions stay in the millisecond range instead of spanning a user's checkout.
- Expiry is free — no cron job scanning for stale reservations, no clock-drift arguments
  between application servers.
- The seat map can be rendered from Redis alone.

**What it costs — state this out loud in an interview**

- **Holds are not durable.** If Redis loses its data, every in-flight hold vanishes and
  those seats instantly look available. During a flash sale that means real double-selling
  risk. The mitigation is the `WHERE status = 'available'` guard on the confirming UPDATE
  (Notebook 3): the second confirmation affects 0 rows, and that user gets refunded rather
  than a stranger's seat.
- **Two sources of truth.** "Is this seat free?" needs both Postgres and Redis, and they can
  disagree. Every read path has to know that.
- **Refunds become a real workflow**, not an edge case, because the guard above will
  occasionally fire.

The alternative — a `reserved_until` column in Postgres — is durable and single-source, but
buys you a cleanup cron, more write load on the hottest table in the system, and lock
contention on exactly the rows everyone is fighting over. Notebook 3 walks through both.

---

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Seat Selection & Locking | Row-level locking, `SELECT ... FOR UPDATE`, race conditions, optimistic concurrency |
| 2 | Handling Flash Sales | Virtual waiting queues with Redis sorted sets, controlling user flow under extreme load |
| 3 | Payment & Reservation Flow | Redis distributed locks (SET NX EX), temporary holds with TTL, payment confirmation |
| 4 | Scaling Ticket Inventory | Caching seat maps with Redis, read-through pattern, cache invalidation strategies |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd 06-system-designs/ticketmaster

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
- **URL**: http://localhost:8081
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `ticketmaster`
- **Use for**: Watch ticket status changes, inspect bookings, see locking behavior

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5541
- **First time setup**: Click "Add Redis Database" → Host `localhost`, Port `6380`
- **Use for**: Watch lock keys appear/expire, monitor TTLs, see queue positions

## Core Entities

| Entity | Purpose |
|--------|---------|
| **Event** | A performer at a venue on a date (e.g., "Taylor Swift at MSG") |
| **Venue** | Physical location with a seat map (sections → rows → seats) |
| **Performer** | Artist, band, team, or speaker |
| **Ticket** | One per seat per event — status is `available` or `sold`. There is deliberately no `held` status; see the design decision above. |
| **Booking** | Groups tickets into a single purchase with payment status |

## Key Concepts Covered

### No Double Booking (Consistency)
- PostgreSQL transactions with `SELECT ... FOR UPDATE`
- Optimistic concurrency control (version columns)
- Redis distributed locks for temporary reservations

### Handling Extreme Load (Flash Sales)
- Virtual waiting queues backed by Redis sorted sets
- Controlled admission to prevent system overload
- Real-time position updates via Server-Sent Events (SSE)

### Payment Flow
- Reserve → Pay → Confirm (two-phase booking)
- Redis TTL for automatic reservation expiry
- Idempotent webhook handling for payment confirmation

### Scaling Reads
- Caching event and venue data in Redis
- Read-through cache pattern
- Cache invalidation when ticket status changes

## API Design

```
GET  /events/:eventId              → Event & Venue & Performer & Ticket[]
GET  /events/search?keyword=...    → Event[]
POST /bookings/reserve             → { bookingId, expiresAt }
POST /bookings/confirm             → { bookingId, status: "confirmed" }
```

## Architecture Overview

```
Client  ──>  API Gateway  ──>  Booking Service  ──>  Redis (Locks + Queue)
                   │                  │                     │
                   │                  └──>  PostgreSQL  <───┘
                   │                        (source of truth)
                   └──>  Event Service  ──>  Redis Cache  ──>  PostgreSQL
```

## License

Educational content — feel free to use and modify for learning purposes.
