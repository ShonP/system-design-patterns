# Multi-Step Processes Pattern

Learn how to build reliable workflows that survive failures, restarts, and long-running operations.

## The Problem

Real-world systems coordinate multiple services to complete a user request:

```
Order Fulfillment Example:
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  1. Charge Payment  ──►  2. Reserve Inventory  ──►  3. Ship    │
│         │                        │                      │       │
│         ▼                        ▼                      ▼       │
│    [Payment API]           [Inventory DB]        [Shipping API] │
│                                                                 │
│  What if server crashes HERE? ─────────────────────────► 💥     │
│  - Payment charged                                              │
│  - Inventory NOT reserved                                       │
│  - Customer confused!                                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Solutions Covered

| Notebook | Topic | Concept |
|----------|-------|---------|
| 01 | The Problem | Why multi-step is hard |
| 02 | Naive Approach | Single server orchestration |
| 03 | Event Sourcing | Using event logs for recovery |
| 04 | Temporal Basics | Introduction to durable execution |
| 05 | Failures & Heartbeats | How Temporal survives crashes |
| 06 | Signals & Timers | Waiting for external events |

## Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                     Temporal Architecture                       │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [Client App]                                                   │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Temporal Server                             │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │  │  Frontend   │  │   History   │  │  Matching   │     │   │
│  │  │  Service    │  │   Service   │  │   Service   │     │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  │                          │                               │   │
│  │                          ▼                               │   │
│  │                   [PostgreSQL]                           │   │
│  │                   (Event History)                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                          │                                      │
│                          ▼                                      │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Worker Pool                           │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐              │   │
│  │  │ Worker 1 │  │ Worker 2 │  │ Worker 3 │   ...        │   │
│  │  │(Workflow)│  │(Activity)│  │(Activity)│              │   │
│  │  └──────────┘  └──────────┘  └──────────┘              │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

## How Temporal Survives Crashes

```
Normal Execution:
─────────────────────────────────────────────────────────────────
t=0:  Start workflow
t=1:  Activity 1 (charge payment) ──► Result saved to history
t=2:  Activity 2 (reserve inventory) ──► Result saved to history
t=3:  Activity 3 (ship order) ──► Result saved to history
t=4:  Workflow complete ✅

With Crash:
─────────────────────────────────────────────────────────────────
t=0:  Start workflow
t=1:  Activity 1 (charge payment) ──► Result saved to history
t=2:  Worker CRASHES! 💥
      
      ... Temporal detects missing heartbeat ...
      
t=5:  New worker picks up workflow
t=5:  Replay: Activity 1 ──► Skip! (result in history)
t=6:  Activity 2 (reserve inventory) ──► Continues from here!
t=7:  Activity 3 (ship order)
t=8:  Workflow complete ✅
```

## Quick Start

```bash
# Start services
docker compose up -d

# Wait for Temporal to be ready
sleep 30

# Install dependencies
uv sync

# Open notebooks
jupyter notebook notebooks/
```

## Services

| Service | Port | URL |
|---------|------|-----|
| Temporal Web UI | 8080 | http://localhost:8080 |
| Temporal Server | 7233 | (gRPC) |
| PostgreSQL | 5432 | postgres://postgres:postgres@localhost:5432/temporal |
| Adminer (Postgres GUI) | 8081 | http://localhost:8081 |
| Redis | 6379 | redis://localhost:6379 |
| RedisInsight (Redis GUI) | 5540 | http://localhost:5540 |

## Notebook Dependencies

| Notebook | Needs | Why |
|----------|-------|-----|
| 01 | Pure Python | Shows the problem without any infra |
| 02 | PostgreSQL | Persists workflow state in a SQL table |
| 03 | Redis | Stores the event log as a Redis Stream |
| 04–06 | Temporal + PostgreSQL | Durable execution engine |

Start everything with `docker compose up -d` before running the notebooks.

## Key Concepts

1. **Workflow** - The overall process (deterministic code)
2. **Activity** - Individual steps (can have side effects)
3. **History** - Recorded events for replay
4. **Heartbeat** - Worker saying "I'm still alive"
5. **Signal** - External event sent to workflow
6. **Timer** - Durable wait (survives crashes)
