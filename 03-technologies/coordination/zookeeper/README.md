# ZooKeeper Deep Dive

📖 **Source**: [Hello Interview – ZooKeeper Deep Dive](https://www.hellointerview.com/learn/system-design/03-technologies/coordination/zookeeper)

## Overview

Coordinating distributed systems is hard. When you have dozens of servers that need to agree on who's the leader, share configuration, or take turns accessing a resource, you need a coordination service. **ZooKeeper** is that service.

Think of ZooKeeper as a **tiny, reliable shared file system** that all your servers can read and write to. It's not meant for storing big data — it stores small pieces of coordination data (who's the leader, what's the current config, who holds the lock).

### Why ZooKeeper?

| Problem | Without ZooKeeper | With ZooKeeper |
|---------|-------------------|----------------|
| **Distributed Locks** | Race conditions, data corruption | Safe, automatic lock release on crash |
| **Leader Election** | Split-brain, multiple leaders | One leader, automatic failover |
| **Config Management** | Stale configs, manual restarts | Instant updates via watches |

### How ZooKeeper Works (Simple Version)

ZooKeeper stores data in **ZNodes** — like files in a tree:

```
/
├── /app
│   ├── /app/config          ← stores config data
│   ├── /app/leader           ← stores current leader
│   └── /app/locks
│       ├── /app/locks/lock-0001  ← ephemeral node (auto-deleted on disconnect)
│       └── /app/locks/lock-0002
```

Key concepts:
- **ZNodes**: Small data nodes (like files) organized in a tree
- **Ephemeral nodes**: Auto-deleted when the client disconnects (great for locks & leader election)
- **Sequential nodes**: ZooKeeper appends a monotonically increasing number (great for ordering)
- **Watches**: Get notified instantly when a ZNode changes (great for config updates)
- **Ensemble**: A cluster of ZooKeeper servers (usually 3 or 5) for fault tolerance

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Distributed Coordination | Why you need distributed locks and how ZooKeeper provides them |
| 2 | Leader Election | How to safely elect one leader among many servers |
| 3 | Configuration Management | How to push config changes to all servers instantly |
| 4 | Service Discovery | How services self-register and clients get a live, auto-updating list |
| 5 | Sessions, Watches & When Not to Use ZooKeeper | Session semantics, watch gotchas, ZAB/quorum, and the limits of ZooKeeper |

Each notebook follows a **Bad → Better → Best** pattern:
- **🔴 Bad**: The naive approach and why it fails
- **🟡 Better**: A common improvement and its limitations
- **🟢 Best**: The ZooKeeper solution and why it works

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- No prior ZooKeeper experience needed!

## Quick Start

```bash
# Navigate to the lab directory
cd 03-technologies/coordination/zookeeper

# Start a 3-node ZooKeeper ensemble
docker compose up -d

# Install dependencies
uv sync

# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/

# Open the first notebook and start learning!
```

## Verify ZooKeeper Is Running

After `docker compose up -d`, verify all 3 nodes are healthy:

```bash
# Check that all containers are running
docker compose ps

# Ask each node "are you ok?" (ZooKeeper's built-in health check)
echo ruok | nc localhost 2181    # should print "imok"
echo ruok | nc localhost 2182    # should print "imok"
echo ruok | nc localhost 2183    # should print "imok"
```

## Architecture

```
┌─────────────────────────────────────────────┐
│              Your Notebooks                  │
│  (Python + kazoo library)                    │
│                                              │
│  Connects to ZooKeeper on localhost:2181     │
└──────────────┬──────────────────────────────┘
               │
    ┌──────────▼──────────┐
    │   ZooKeeper Ensemble │
    │                      │
    │  ┌──────┐ ┌──────┐  │
    │  │ zoo1 │ │ zoo2 │  │  ← 3 nodes for fault tolerance
    │  │:2181 │ │:2182 │  │    (survives 1 node failure)
    │  └──────┘ └──────┘  │
    │       ┌──────┐      │
    │       │ zoo3 │      │
    │       │:2183 │      │
    │       └──────┘      │
    └─────────────────────┘
```

## Cleanup

```bash
# Stop all containers
docker compose down

# Remove all data (if you want a fresh start)
docker compose down -v
```

## License

Educational content — feel free to use and modify for learning purposes.
