# 🏗️ System Design Labs

Hands-on Python notebooks for learning system design patterns through practical examples.

## 🎯 Purpose

This repository provides **interactive, runnable examples** of common system design patterns. Instead of just reading about these concepts, you can:

- Run real code that demonstrates each pattern
- See failures happen and understand why
- Compare different approaches side-by-side
- Experiment with configurations and observe effects

Each pattern includes Docker-based infrastructure (PostgreSQL, Redis, MinIO, Temporal) so you can run everything locally with visualization tools like Adminer and RedisInsight.

## 📚 Patterns

| Pattern | Description | Notebooks |
|---------|-------------|-----------|
| [Real-Time Updates](patterns/real-time-updates/) | Polling, SSE, WebSockets, pub/sub | 7 |
| [Dealing with Contention](patterns/contention/) | Locks, optimistic concurrency, CRDTs | 5 |
| [Scaling Reads](patterns/scaling-reads/) | Caching, read replicas, materialized views | 6 |
| [Scaling Writes](patterns/scaling-writes/) | Sharding, partitioning, write buffering | 6 |
| [Handling Large Blobs](patterns/large-blobs/) | Chunked uploads, presigned URLs, CDN | 6 |
| [Long Running Tasks](patterns/long-running-tasks/) | Queues, workers, DLQ, backpressure | 6 |
| [Multi-Step Processes](patterns/multi-step-processes/) | Workflows, sagas, Temporal | 6 |

## 🚀 Getting Started

### Prerequisites

- Python 3.10+
- Docker & Docker Compose
- [uv](https://github.com/astral-sh/uv) (recommended) or pip

### Quick Start

```bash
# Clone the repository
git clone https://github.com/your-username/system-design-labs.git
cd system-design-labs

# Pick a pattern to explore
cd patterns/real-time-updates

# Start the infrastructure
docker compose up -d

# Install dependencies
pip install -r requirements.txt

# Open notebooks
jupyter notebook notebooks/
```

### Visualization Tools

Each pattern includes web UIs for observing what's happening:

| Tool | Purpose | Common Port |
|------|---------|-------------|
| Adminer | PostgreSQL GUI | 8080 or 8081 |
| RedisInsight | Redis GUI | 5540 |
| MinIO Console | Object storage GUI | 9001 |
| Temporal UI | Workflow visualization | 8080 |

## 📖 Pattern Overview

### 1. Real-Time Updates
*How do you push data to clients instantly?*

- **Polling** - Simple but wasteful
- **Long Polling** - Better, but still has overhead
- **Server-Sent Events** - One-way streaming
- **WebSockets** - Bidirectional communication
- **Pub/Sub** - Decoupled message delivery

### 2. Dealing with Contention
*What happens when multiple users edit the same data?*

- **Pessimistic Locking** - Lock first, edit later
- **Optimistic Concurrency** - Detect conflicts on save
- **CRDTs** - Conflict-free data structures
- **Last-Write-Wins** - Simple but lossy

### 3. Scaling Reads
*How do you handle millions of read requests?*

- **Caching** - Store frequent queries in memory
- **Read Replicas** - Distribute load across databases
- **Materialized Views** - Pre-compute expensive queries
- **Cache Invalidation** - The hardest problem in CS

### 4. Scaling Writes
*How do you handle high write throughput?*

- **Partitioning** - Split data across nodes
- **Sharding** - Route writes to specific nodes
- **Write Buffering** - Batch writes for efficiency
- **Event Sourcing** - Append-only writes

### 5. Handling Large Blobs
*How do you upload/download large files reliably?*

- **Chunked Uploads** - Split files into pieces
- **Presigned URLs** - Direct client-to-storage uploads
- **Resumable Uploads** - Continue after failures
- **CDN Integration** - Serve files from edge locations

### 6. Long Running Tasks
*How do you process jobs that take minutes or hours?*

- **Message Queues** - Decouple producers and consumers
- **Worker Pools** - Scale processing independently
- **Dead Letter Queues** - Handle poison messages
- **Backpressure** - Prevent queue overflow

### 7. Multi-Step Processes
*How do you coordinate workflows across services?*

- **Sagas** - Compensating transactions
- **Workflow Engines** - Durable execution
- **Event Sourcing** - Replay for recovery
- **Temporal** - Production-grade workflows

## 🏛️ Repository Structure

```
system-design-labs/
├── README.md
└── patterns/
    ├── real-time-updates/
    │   ├── README.md
    │   ├── docker-compose.yml
    │   ├── requirements.txt
    │   └── notebooks/
    │       ├── 01_polling.ipynb
    │       ├── 02_long_polling.ipynb
    │       └── ...
    ├── contention/
    │   └── ...
    └── ...
```

Each pattern follows the same structure:
- **README.md** - Pattern overview and architecture
- **docker-compose.yml** - Infrastructure setup
- **requirements.txt** - Python dependencies
- **notebooks/** - Interactive Jupyter notebooks
- **db/** (optional) - SQL initialization scripts

## 🎓 How to Learn

1. **Read the pattern README** - Understand the problem and solutions
2. **Start Docker services** - `docker compose up -d`
3. **Run notebooks in order** - Each builds on the previous
4. **Experiment** - Change parameters, break things, observe
5. **Check visualization tools** - See data flow in real-time

## 🤝 Contributing

Contributions welcome! Ideas for new patterns:
- Rate Limiting
- Circuit Breakers
- Leader Election
- Distributed Transactions
- Search Indexing

## 📝 License

MIT License - Use freely for learning and teaching.

## 🙏 Acknowledgments

Inspired by system design resources from:
- [Hello Interview](https://www.hellointerview.com/)
