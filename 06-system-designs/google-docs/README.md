# Google Docs — Collaborative Document Editor System Design Lab

📖 **Source**: [Hello Interview – Design Google Docs](https://www.hellointerview.com/learn/system-design/problem-breakdowns/google-docs)

## Overview

Google Docs is a browser-based collaborative document editor. Multiple users can edit the same document at the same time, see each other's cursors, and view changes in real-time.

This lab walks you through the core building blocks of such a system — step by step, with real, runnable code. You will work with a live **WebSocket collaboration server**, **PostgreSQL** for durable storage of documents and operations, and **Redis** for presence tracking and cross-server awareness.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Operational Transformation Basics | How OT resolves conflicts when users edit the same position concurrently |
| 2 | Conflict Resolution with CRDTs | An alternative approach where operations commute — no central server needed |
| 3 | Real-Time Collaboration via WebSockets | Building the live editing experience with WebSocket connections and presence |
| 4 | Document Versioning and History | Snapshots, compaction, and restoring previous versions |

## Architecture

```
┌──────────┐  WebSocket   ┌──────────────┐  SQL    ┌────────────┐
│  Client   │◄────────────►│  Doc Server  │◄───────►│ PostgreSQL │
│ (notebook)│              │  (Python)    │         │            │
└──────────┘              └──────┬───────┘         └────────────┘
                                 │
                           presence + awareness
                                 │
                          ┌──────▼───────┐
                          │    Redis     │
                          └──────────────┘
```

## Core Concepts Covered

### Data Model
- **Users** — accounts with display names and cursor colors
- **Documents** — text documents with version tracking
- **Operations** — append-only log of insert/delete edits (the OT log)
- **Snapshots** — periodic compactions of the full document text (for versioning)
- **Collaborators** — who has access and what role (owner/editor/viewer)

### Collaborative Editing Approaches

| Approach | How It Works | Trade-offs |
|----------|-------------|------------|
| **Operational Transformation (OT)** | Transform each operation against concurrent ops before applying | Low memory, fast; needs central server |
| **CRDTs** | Operations commute — can be applied in any order | No central server needed; higher memory (tombstones) |

### Document Flow
1. Client sends `edit` over WebSocket, quoting the **revision** it edited against
   (e.g., INSERT at position 5, revision 12)
2. Server transforms it against every op applied since that revision (OT)
3. Server applies the transformed op(s) to the in-memory document
4. Server transforms every *other* editor's cursor by the same op, so carets
   follow their character instead of drifting to a stale offset
5. Server persists the operation to the **operations** table
6. Server ACKs the sender with the op it actually applied and the new revision
7. Server broadcasts the transformed op to all other editors

A delete can transform into **two** ops (someone typed inside the range being
deleted) or **zero** (someone already deleted it), which is why the ACK carries
a list rather than a single op.

### Versioning & Compaction
- **Snapshots**: periodically compress the operations log into a full document text
- **Auto-snapshot**: triggers every 50 operations
- **Restore**: revert to any previous snapshot version
- **Efficient loading**: load latest snapshot + replay only recent ops

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL and WebSockets

## Quick Start

```bash
# Navigate to the lab directory
cd 06-system-designs/google-docs

# Start PostgreSQL + Redis + Doc Server + Visualization Tools
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
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `googledocs_demo`
- **Use for**: Inspect operations log, snapshots, document metadata

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch presence data, cursor positions, document session state

## Key Design Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| Transport | WebSockets | Bi-directional, low-latency, persistent connections for real-time editing |
| Conflict resolution | OT (primary), CRDTs (explored) | OT is what Google Docs uses; CRDTs are a great alternative to learn |
| Document store | PostgreSQL | Durable, relational, easy to query for demos |
| Operations log | Append-only table | Captures every edit for replay, versioning, and OT |
| Presence | Redis hashes | Fast reads, cross-server capable, naturally ephemeral |
| Versioning | Snapshots table | Efficient loading, compact storage, supports history/restore |

## Honest Scope

This lab is small enough to read in an afternoon, which means it stops short of
a real editor in specific ways. The notebooks call each of these out where they
bite:

| Not implemented | Where it matters |
|-----------------|------------------|
| **TP2** (three-way concurrency) | NB1 shows a 4-op counterexample. Real OT leans on the server's total order instead. |
| Client-side pending queue | `DocClient` waits for the ACK instead of echoing keystrokes optimistically and transforming remote ops against un-ACKed ones. |
| Rich text | Only insert/delete of plain characters. No bold/table/image attribute ops. |
| Tombstone GC, causality | The CRDT keeps every tombstone forever and has no version vectors. |
| Undo | Undo is "inverse of *my* last op, transformed against everything since" — not covered. |
| Reconnect / resync | A dropped socket loses the client's revision; there is no fast-forward path. |

## Real-World Context

| System | Approach | Notes |
|--------|----------|-------|
| Google Docs | OT | Central server transforms; max ~100 concurrent editors per doc |
| Figma | CRDT-inspired | Custom CRDT optimized for design tool operations |
| Apple Notes | CRDT | Uses CRDTs for offline-first sync across devices |
| VS Code Live Share | OT | Central relay server for edit coordination |

## License

Educational content — feel free to use and modify for learning purposes.
