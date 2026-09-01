# Dealing with Contention Pattern

🔒 **Contention** occurs when multiple processes compete for the same resource simultaneously. This could be booking the last concert ticket, bidding on an auction item, or any similar scenario. Without proper handling, you get race conditions, double-bookings, and inconsistent state.

## Overview

This pattern walks you through solutions from simple database transactions to more complex distributed coordination, showing when optimistic concurrency beats pessimistic locking and how to scale beyond single-node constraints.

## The Problem

Consider buying concert tickets online. There's 1 seat left for The Weeknd concert. Alice and Bob both want this last seat and click "Buy Now" at exactly the same moment:

```
Timeline of a Race Condition:
────────────────────────────────────────────────────────────────────
Alice's Request                    Bob's Request
────────────────────────────────────────────────────────────────────
READ: "1 seat available"           
                                   READ: "1 seat available"
CHECK: 1 >= 1 ✓                    
                                   CHECK: 1 >= 1 ✓
UPDATE: seats = 0, charge $500     
                                   UPDATE: seats = -1, charge $500
                                   
Result: Both get confirmation for the SAME seat! 🔥
────────────────────────────────────────────────────────────────────
```

The race condition happens because reading and writing aren't atomic. There's a gap between "check the current state" and "update based on that state" where the world can change.

## Notebooks in This Series

### Part 1: Understanding Race Conditions
- The concert ticket problem
- Why basic code fails under concurrency
- Visualizing race conditions

### Part 2: Atomicity and Transactions
- Database transactions basics
- ACID properties
- Why transactions alone don't prevent all race conditions
- **The simplest fix: atomic `UPDATE ... WHERE` guards**

### Part 3: Pessimistic Locking
- `SELECT ... FOR UPDATE`
- Row-level vs table-level locks
- Deadlock prevention

### Part 4: Optimistic Concurrency Control
- Version columns and compare-and-swap
- Using existing data as versions
- The ABA problem

### Part 5: Distributed Coordination
- Two-Phase Commit (2PC)
- Distributed locks (Redis, Database)
- Saga pattern
- When to use each approach

## Prerequisites

- Python 3.10+
- [uv](https://docs.astral.sh/uv/) (fast Python package manager)
- Docker & Docker Compose (for PostgreSQL)
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the pattern directory
cd 04-patterns/dealing-with-contention

# Start PostgreSQL + Redis + Visualization Tools
docker compose up -d

# Install dependencies
uv sync

# Register a Jupyter kernel that points at this lab's .venv
# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/

# Open the notebooks in VS Code and pick the "Contention (Python)" kernel
# (top-right of the notebook). If it doesn't appear: Cmd+Shift+P → "Reload Window"
```

## 🔍 Visualization Tools (Included in Docker)

These tools help you see database changes in real-time while running the notebooks:

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System: `PostgreSQL`, Server: `postgres`, Username: `demo`, Password: `demo`, Database: `contention_demo`
- **Use for**: Watch `concerts.available_seats` change, see `tickets` being created, view `transaction_log`

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host: `redis`, Port: `6379`
- **Use for**: Watch distributed locks being acquired/released in Notebook 5

## Real-World Applications

| Application | Pattern | Why |
|-------------|---------|-----|
| Ticketmaster | Pessimistic + Reservations | Seat selection with time-limited holds |
| eBay Auctions | Optimistic Concurrency | High bid as version, rare conflicts |
| Banking | 2PC / Sagas | Cross-account transfers need atomicity |
| Uber | Distributed Locks | Driver assignment coordination |
| Flash Sales | Queue Serialization | Hot partition problem |
| Yelp Reviews | Optimistic Concurrency | Rating updates with review count as version |

## Decision Flowchart

```
                    ┌─────────────────────────────┐
                    │ Is all data in one database?│
                    └─────────────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
                  Yes                       No
                    │                       │
                    ▼                       ▼
            ┌───────────────┐      ┌───────────────────┐
            │ High          │      │ Need strict       │
            │ contention?   │      │ atomicity?        │
            └───────────────┘      └───────────────────┘
                    │                       │
        ┌───────────┴───────────┐   ┌───────┴───────┐
        ▼                       ▼   ▼               ▼
       Yes                     No  Yes              No
        │                       │   │               │
        ▼                       ▼   ▼               ▼
┌───────────────┐      ┌───────────────┐   ┌───────────────┐
│ Pessimistic   │      │ Optimistic    │   │ Saga          │
│ Locking       │      │ Concurrency   │   │ Pattern       │
└───────────────┘      └───────────────┘   └───────────────┘
                                                    │
                                           ┌───────┴───────┐
                                           ▼               ▼
                                   ┌───────────────┐ ┌───────────────┐
                                   │ 2PC           │ │ Distributed   │
                                   │ (if needed)   │ │ Locks         │
                                   └───────────────┘ └───────────────┘
```

## Key Takeaways

1. **Start simple** - Exhaust single-database solutions before distributed coordination
2. **Pessimistic locking** - Use when contention is high and predictable
3. **Optimistic concurrency** - Use when conflicts are rare
4. **Distributed coordination** - Only when data spans multiple databases
5. **Reservations** - Improve UX by preventing users from entering contention

## License

Educational content - feel free to use and modify for learning purposes.
