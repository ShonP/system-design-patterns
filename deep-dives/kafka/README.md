# Kafka Deep Dive

📖 **Source**: [Hello Interview – Kafka Deep Dive for System Design Interviews](https://www.hellointerview.com/learn/system-design/deep-dives/kafka)

## Overview

Apache Kafka is an open-source distributed event streaming platform used by 80% of the Fortune 100. It can act as both a **message queue** and a **stream processing system**, delivering high performance, scalability, and durability.

Think of Kafka like a super-powered log file shared across many servers. Producers write messages to it, and consumers read messages from it. Messages are organized into **topics** (logical categories) and split across **partitions** (for parallel processing). This architecture lets Kafka handle millions of messages per second.

This lab walks you through Kafka hands-on — from sending your first message to understanding exactly-once delivery and stream processing patterns.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Producers and Consumers | Sending and receiving messages, topics, offsets, message structure |
| 2 | Partitioning and Consumer Groups | Partition keys, parallel consumption, rebalancing, hot partitions |
| 3 | Exactly-Once Semantics | Delivery guarantees, idempotent producers, transactional messaging |
| 4 | Kafka Streams Intro | Real-time stream processing patterns: filtering, aggregation, windowing |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- No prior Kafka experience needed!

## Quick Start

```bash
# Navigate to the lab directory
cd deep-dives/kafka

# Start Kafka + Kafka UI
docker-compose up -d

# Create virtual environment and install dependencies
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Register Jupyter kernel
python -m ipykernel install --user --name=kafka --display-name="Kafka (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Kafka UI
- **URL**: http://localhost:8080
- **Use for**: Browse topics, view messages, inspect partitions, monitor consumer groups
- No login needed — just open the URL after `docker-compose up -d`

## Architecture (What Docker Sets Up)

```
┌─────────────────────────────────────────────────────┐
│  Docker Compose                                     │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  Kafka Broker (KRaft mode - no Zookeeper!)    │  │
│  │  Port 9092 (external) / 29092 (internal)      │  │
│  │                                               │  │
│  │  Topics → Partitions → Messages               │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  Kafka UI                                     │  │
│  │  http://localhost:8080                         │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘

Your Python notebooks connect to localhost:9092
```

> **Note**: We use KRaft mode (Kafka without Zookeeper). Newer versions of Kafka have a built-in consensus mechanism called KRaft, making the setup simpler — one less service to manage!

## Key Concepts Covered

### Core Building Blocks
- **Broker** — a single Kafka server that stores data and serves clients
- **Topic** — a logical category for messages (like a folder)
- **Partition** — a physical, ordered log within a topic (how Kafka scales)
- **Offset** — a unique position number for each message in a partition
- **Producer** — writes messages to topics
- **Consumer** — reads messages from topics
- **Consumer Group** — a team of consumers that split the work

### When to Use Kafka
- **As a Message Queue**: async processing, decoupling services, ordered task execution
- **As a Stream**: real-time analytics, event-driven architectures, multi-consumer broadcasting

### Important Design Decisions
- **Partition Key Choice** — determines message distribution and ordering
- **Consumer Group Design** — controls parallelism and fault tolerance
- **Delivery Guarantees** — at-most-once, at-least-once, exactly-once trade-offs
- **Retention Policy** — how long to keep messages (default: 7 days)

## Real-World Examples

| System | How Kafka Is Used |
|--------|-------------------|
| YouTube | Video upload events → async transcoding workers |
| Ticketmaster | Virtual waiting queue — users processed in arrival order |
| Ad Platforms | Click event streams → real-time aggregation |
| Facebook Live | Comments published to stream → delivered to all viewers |
| Web Crawlers | URLs queued for download → parsed by separate workers |

## Troubleshooting

### Kafka won't start
```bash
# Check if the container is running
docker-compose ps

# View logs
docker-compose logs kafka

# Restart everything
docker-compose down -v && docker-compose up -d
```

### Can't connect from Python
- Make sure Docker is running and healthy: `docker-compose ps`
- The broker should show `(healthy)` status
- Python connects to `localhost:9092` (the external listener)

### Kafka UI shows no topics
- Topics are created automatically when you run the notebooks
- Or create one manually in the UI: click "Topics" → "Add a Topic"

## License

Educational content — feel free to use and modify for learning purposes.
