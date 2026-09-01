# WhatsApp — Messaging System Design Lab

📖 **Source**: [Hello Interview – Design a Messaging App Like WhatsApp](https://www.hellointerview.com/learn/system-design/problem-breakdowns/whatsapp)

## Overview

WhatsApp is a messaging service that delivers billions of messages per day with low latency, offline support, and end-to-end encryption. This lab walks you through the core building blocks of such a system — step by step, with real, runnable code.

You will work with a live **WebSocket chat server**, **PostgreSQL** for durable storage, and **Redis** for pub/sub fan-out and presence tracking. Every concept is demonstrated with code you can modify and experiment with.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Message Delivery & Storage | Bad→best progression (polling vs WebSocket), WebSocket messaging, inbox pattern, offline delivery, Redis pub/sub |
| 2 | Read Receipts & Presence | Delivered/read status, online/offline tracking, heartbeats, typing indicators, media handling with signed URLs |
| 3 | Group Messaging | Fan-out to participants, partitioning strategies, admin controls |
| 4 | End-to-End Encryption Basics | Public/private keys, encrypting messages, why the server can't read them |

## Architecture

```
┌──────────┐  WebSocket   ┌──────────────┐  SQL    ┌────────────┐
│  Client   │◄────────────►│  Chat Server │◄───────►│ PostgreSQL │
│ (notebook)│              │  (Python)    │         │            │
└──────────┘              └──────┬───────┘         └────────────┘
                                 │
                           pub/sub + presence
                                 │
                          ┌──────▼───────┐
                          │    Redis     │
                          └──────────────┘
```

## Core Concepts Covered

### Data Model
- **Users** — accounts that send and receive messages
- **Chats** — 1:1 or group conversations (up to 100 participants)
- **Messages** — text content with per-chat sequence numbers
- **Inbox** — pending deliveries for offline users; status advances `pending → delivered → read` (never backwards)

### Message Flow
1. Sender sends `send_message` over WebSocket
2. Server persists to **Messages** table + creates **Inbox** rows (durable)
3. Server ACKs the sender
4. Server publishes to **Redis pub/sub** per-recipient channel (real-time, best-effort)
5. Recipient's server forwards to their WebSocket
6. Recipient sends `ack` → inbox status becomes `delivered`, and a `delivery_receipt` is published back to the sender

### Presence & Read Receipts
- **Presence**: Redis keys with TTL, refreshed by heartbeats
- **Last seen**: stored on disconnect
- **Read receipts**: inbox status transitions `pending → delivered → read`

### What This Toy Does NOT Do

Worth being explicit, so the lab doesn't oversell itself:

- **Single chat server.** `connections` is an in-process dict. Real WhatsApp shards users
  across thousands of servers with a consistent-hash routing layer.
- **Redis pub/sub is at-most-once.** No persistence, no replay. The inbox table is what
  makes delivery reliable; pub/sub is only the fast path.
- **No forward secrecy.** Notebook 4 uses static RSA keys, not the Signal Double Ratchet.
- **No presence fan-out.** `get_presence` is a pull. Real clients get pushed presence
  updates for the contacts they have open.
- **Inbox rows are never pruned.** They accumulate forever once read.

### Scaling (discussed in notebooks)
- Redis pub/sub partitioned by user (optimal for 1:1-heavy workloads)
- Consistent hashing to assign users to chat servers
- Heartbeat + sequence numbers to detect missed messages

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL and WebSockets

## Quick Start

```bash
# Navigate to the lab directory
cd 06-system-designs/whatsapp

# Start PostgreSQL + Redis + Chat Server + Visualization Tools
docker compose up -d --build

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
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `whatsapp_demo`
- **Use for**: Inspect messages, inbox rows, chat participants

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch pub/sub channels, presence keys, TTLs

## Key Design Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| Transport | WebSockets | Bi-directional, low latency, persistent connection |
| Message store | PostgreSQL | Durable, relational, easy to query for demos |
| Real-time delivery | Redis pub/sub | Lightweight, per-user channels, no disk overhead |
| Presence | Redis with TTL | Automatic expiry, fast reads |
| Offline delivery | Inbox table + sync | Guarantees eventual delivery even if pub/sub drops |
| Ordering | Per-chat sequence numbers | The counter row is locked for the whole send transaction, so sequence order == commit order. Ordering is **per conversation**, not global — there is no cross-chat total order, and none is needed |
| Duplicate sends | `client_message_id` unique index | A retried send after a lost ACK is a no-op instead of a second message (Notebook 1, "At-Least-Once Is Not Exactly-Once") |

## License

Educational content — feel free to use and modify for learning purposes.
