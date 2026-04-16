# Ticketmaster System Design Lab

📖 **Source**: [Hello Interview – Design Ticketmaster](https://www.hellointerview.com/learn/system-design/problem-breakdowns/ticketmaster)

## Overview

Ticketmaster is a ticket booking platform where millions of users compete for a limited number of seats. The core engineering challenge: **how do you let 10 million people try to book the same 20,000 seats without selling any seat twice?**

This lab walks you through the hardest parts of the design — seat locking, flash sales, payment flows, and scaling — with real, runnable code against PostgreSQL and Redis.

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
cd system-designs/ticketmaster

# Start PostgreSQL + Redis + Visualization Tools
docker-compose up -d

# Install dependencies
uv sync

# Register Jupyter kernel
uv run python -m ipykernel install --user --name=ticketmaster --display-name="Ticketmaster (Python)"

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
| **Ticket** | One per seat per event — status is `available` or `sold` |
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
