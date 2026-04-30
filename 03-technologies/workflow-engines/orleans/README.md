# Virtual Actors with Microsoft Orleans

📖 **What you'll learn**: How to build distributed systems with the Virtual Actor Model using Microsoft Orleans — from your first grain to stateful actors, streams, AI agents, and production monitoring.

## The Problem

Imagine you're building a system that manages millions of IoT devices, each reporting telemetry every 30 seconds. Each device needs:

1. **Its own state** — last known temperature, battery level, firmware version
2. **Scheduled tasks** — check for firmware updates every 6 hours
3. **Event processing** — react to anomalies in real-time
4. **Durable memory** — survive server restarts without losing data
5. **Scalability** — handle millions of devices across a cluster

You could build this with microservices + databases + message queues + cron jobs... or you could model each device as a **virtual actor** that Orleans manages for you.

### Why Virtual Actors?

Traditional actor systems (like Akka) require you to explicitly create, supervise, locate, and destroy actors. Orleans **virtual actors** (called **grains**) are different:

- **Always addressable** — reference a grain by ID, Orleans handles the rest
- **Activated on demand** — grains spin up when called, deactivate when idle
- **Location transparent** — grains can live on any server in the cluster
- **Single-threaded** — no locks, no races, no concurrent access bugs
- **Durable** — state survives crashes via pluggable persistence

```
Traditional Actor System:                Orleans Virtual Actors:

  You: "Create actor A"                    You: "Call grain A"
  You: "Where is actor A?"                 Orleans: "I'll find/create it"
  You: "Is actor A alive?"                 Orleans: "I'll activate if needed"
  You: "Actor A crashed, restart it"       Orleans: "I handle failures"
  You: "Scale actors across servers"       Orleans: "I distribute them"
```

### Who Uses Orleans?

| Company | Use Case |
|---------|----------|
| **Microsoft** | Halo game sessions, Xbox Live, Azure PlayFab |
| **Walmart** | Real-time inventory tracking |
| **Alibaba** | Distributed transaction processing |
| **Electronic Arts** | Game backend services |
| **343 Industries** | Halo Infinite matchmaking |

## Key Concepts Covered

### 🌾 Grains
The fundamental unit in Orleans. Each grain has a stable identity, processes one request at a time, and can persist state. Think of a grain as a lightweight object that lives in a distributed system.

### 🏛️ Silos
The server process that hosts grain activations. Silos form a cluster and automatically distribute grains across themselves.

### 💾 Persistent State
Grains can save their state to PostgreSQL, Redis, Azure Storage, or any pluggable provider. State is automatically loaded when a grain activates.

### ⏰ Timers & Reminders
Timers for high-frequency in-memory work (dies with the grain). Reminders for durable scheduled tasks (survives restarts).

### 📡 Streams
Pub/sub messaging between grains. Producers publish events, consumers subscribe. Orleans manages the plumbing.

### 🤖 AI Agents as Grains
Each AI agent is a grain with durable memory, tool execution via stateless workers, and agent-to-agent communication via grain calls.

## Labs in This Series

| # | Lab | What You'll Learn | Time |
|---|-----|-------------------|------|
| 1 | Hello Grain | Grain interfaces, grain classes, silo setup, client calls | 20 min |
| 2 | Stateful Grain | Persistent state, `[PersistentState]`, state providers | 30 min |
| 3 | Timers & Reminders | In-memory timers, durable reminders, lifecycle | 30 min |
| 4 | Grain Communication | Grain-to-grain calls, order processing pipeline | 30 min |
| 5 | Streams | Pub/sub with Orleans streams, producers, consumers | 30 min |
| 6 | AI Agent Grain | Stateful AI agent, durable memory, tool execution | 30 min |
| 7 | Dashboard & Monitoring | Orleans Dashboard, metrics, health checks | 20 min |

**Total estimated time: ~3.5 hours**

## Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Docker & Docker Compose](https://docs.docker.com/get-docker/) (for PostgreSQL persistence in Lab 02+)
- Basic understanding of C# and async/await

## Quick Start

```bash
# Navigate to the lab directory
cd 03-technologies/workflow-engines/orleans

# Start PostgreSQL for persistence labs
docker compose up -d

# Run your first lab
cd labs/01-hello-grain
dotnet run
```

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Your Code                                  │
│                                                                    │
│  ┌─────────────┐     ┌──────────────┐     ┌───────────────────┐  │
│  │   Client     │────▶│  Orleans      │────▶│   Grains          │  │
│  │  (console/   │     │  Silo         │     │  (your business   │  │
│  │   web app)   │     │  (runtime)    │     │   logic)          │  │
│  │              │     │              │     │                   │  │
│  │ "Call grain   │     │ "I'll find,   │     │ "I process one    │  │
│  │  by ID"      │     │  activate,    │     │  request at a     │  │
│  │              │     │  and route"   │     │  time"            │  │
│  └─────────────┘     └──────┬───────┘     └───────────────────┘  │
│                              │                                     │
│                     ┌────────▼────────┐                           │
│                     │  PostgreSQL      │                           │
│                     │  (grain state,   │                           │
│                     │   reminders,     │                           │
│                     │   membership)    │                           │
│                     └─────────────────┘                           │
└──────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
orleans/
├── README.md              # This file
├── docker-compose.yml     # PostgreSQL for persistence
└── labs/
    ├── 01-hello-grain/         # Your first grain
    ├── 02-stateful-grain/      # Persistent state
    ├── 03-timers-and-reminders/ # Scheduled work
    ├── 04-grain-communication/ # Grain-to-grain calls
    ├── 05-streams/             # Pub/sub messaging
    ├── 06-ai-agent-grain/      # AI agents as grains
    └── 07-dashboard-and-monitoring/ # Observability
```

## Stopping the Lab

```bash
docker compose down          # Stop PostgreSQL
docker compose down -v       # Stop and delete data
```

## License

Educational content — feel free to use and modify for learning purposes.
