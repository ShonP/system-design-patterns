# Real-time Updates Pattern

⚡ **Real-time Updates** addresses the challenge of delivering immediate notifications and data changes from servers to clients as events occur.

## Overview

This pattern covers the architectural approaches to enable low-latency, bidirectional communication - from chat applications where messages need instant delivery to live dashboards showing real-time metrics.

## The Two Hops Problem

When systems require real-time updates, the solution requires two distinct pieces:

1. **First Hop**: How do we get updates from the server to the client?
2. **Second Hop**: How do we get updates from the source to the server?

```
┌──────────┐     Hop 2      ┌──────────┐     Hop 1      ┌──────────┐
│  Source  │ ─────────────► │  Server  │ ─────────────► │  Client  │
│ (Events) │                │          │                │          │
└──────────┘                └──────────┘                └──────────┘
```

## Notebooks in This Series

### Part 1: Networking Fundamentals
- OSI Model basics (Layers 3, 4, 7)
- TCP vs UDP
- HTTP Request lifecycle
- Load Balancers (L4 vs L7)

### Part 2: Simple Polling
- Basic polling implementation
- Advantages and disadvantages
- When to use simple polling

### Part 3: Long Polling
- How long polling works
- Implementation with FastAPI
- Trade-offs and latency considerations

### Part 4: Server-Sent Events (SSE)
- Chunked transfer encoding
- EventSource API
- Building a real-time dashboard

### Part 5: WebSockets
- Full-duplex communication
- Building a chat application
- Connection management and scaling

### Part 6: WebRTC Overview
- Peer-to-peer communication
- STUN/TURN servers
- Use cases (video calls, collaborative editing)

### Part 7: Server-Side Push/Pull
- Pulling via polling (database-backed)
- Pushing via consistent hashing
- Pushing via Pub/Sub (Redis)

### Part 8: Webhooks
- Vendor → your-server push (the inverse of polling)
- HMAC signature verification
- Retries with exponential backoff
- Idempotent handlers and fast-ACK pattern

## Prerequisites

- Python 3.9+
- [uv](https://docs.astral.sh/uv/) (fast Python package manager)
- Docker & Docker Compose
- Basic understanding of HTTP

## Quick Start

```bash
# Navigate to the pattern directory
cd 04-patterns/real-time-updates

# Start the required services (Redis + RedisInsight)
docker-compose up -d

# Install Python dependencies into a local .venv (using uv)
uv sync

# Open any notebook in VS Code, then:
#   1. Click the kernel picker (top-right of the notebook)
#   2. Choose the .venv we just created (Python 3.x .venv/bin/python)
#   3. If the .venv doesn't appear, reload the VS Code window:
#      Cmd+Shift+P → "Developer: Reload Window"
#
# Start with notebooks/01_networking_fundamentals.ipynb
```

### Port already in use (6379)?
If another lab is already running a Redis container on port 6379, the
existing container will work for this lab — you can skip `docker compose up`
and just confirm Redis answers `PING`.

## 🔍 Visualization Tools (Included in Docker)

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host: `redis`, Port: `6379`
- **Use for**: Watch Pub/Sub channels and messages in Notebook 7

## Real-World Applications

| Application | Pattern | Why |
|-------------|---------|-----|
| Ticketmaster | WebSockets + Pub/Sub | Real-time seat availability |
| Uber | WebSockets | Driver location updates |
| WhatsApp | WebSockets | Instant messaging |
| Google Docs | WebSockets + CRDT | Collaborative editing |
| Robinhood | SSE/WebSockets | Stock price updates |
| Live Comments | WebSockets + Pub/Sub | High fan-out broadcasting |

## Decision Flowchart

```
                    ┌─────────────────────────────┐
                    │ Do you need real-time?      │
                    └─────────────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
                  No                       Yes
                    │                       │
                    ▼                       ▼
            ┌───────────────┐    ┌─────────────────────────┐
            │ Simple        │    │ Need bidirectional      │
            │ Polling       │    │ communication?          │
            └───────────────┘    └─────────────────────────┘
                                            │
                                ┌───────────┴───────────┐
                                ▼                       ▼
                               No                      Yes
                                │                       │
                                ▼                       ▼
                        ┌───────────────┐      ┌───────────────┐
                        │ SSE           │      │ Need P2P?     │
                        └───────────────┘      └───────────────┘
                                                        │
                                            ┌───────────┴───────────┐
                                            ▼                       ▼
                                           No                      Yes
                                            │                       │
                                            ▼                       ▼
                                    ┌───────────────┐      ┌───────────────┐
                                    │ WebSockets    │      │ WebRTC        │
                                    └───────────────┘      └───────────────┘
```

## License

Educational content - feel free to use and modify for learning purposes.
