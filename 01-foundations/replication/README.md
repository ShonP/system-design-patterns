# Replication

> Part of `01-foundations/`. Beginner-friendly intro to **data replication**: why we
> copy data across machines, how leader–follower works, and how sync / async / quorum
> models trade off consistency, latency, and availability.

## Learning objectives

- Explain why we replicate data (availability, durability, read scalability).
- Compare leader–follower and leaderless (quorum) replication.
- Reason about synchronous vs asynchronous replication and replication lag.
- Understand the quorum rule **W + R > N** and why it guarantees fresh reads.

## Notebooks

| # | Notebook | What you'll learn |
|---|----------|-------------------|
| 1 | [`01_leader_follower_basics.ipynb`](./notebooks/01_leader_follower_basics.ipynb) | What replication is, why it matters, and a real Postgres 16 primary + streaming replica running in Docker. Write to the primary, read from both, inspect `pg_stat_replication`, watch lag grow under load, and learn about failover and split-brain. |
| 2 | [`02_sync_vs_async_replication.ipynb`](./notebooks/02_sync_vs_async_replication.ipynb) | Pure-Python simulation of sync / semi-sync / async replication. Feel the stale-read problem, measure latency and durability tradeoffs, and implement the **read-your-own-writes** pattern as an explicit bad-practice → best-practice fix. |
| 3 | [`03_quorum_reads_writes.ipynb`](./notebooks/03_quorum_reads_writes.ipynb) | N/W/R quorum model (Dynamo / Cassandra style). Simulate a 3-node leaderless cluster, prove `W + R > N` empirically, see last-write-wins lose data on concurrent writes, and add **read repair** in a few lines. |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose *(only needed for notebook 1; notebooks 2 and 3 are pure Python)*
- [`uv`](https://docs.astral.sh/uv/) for Python dependency management

## Setup

From this folder:

```bash
# 1. Start Postgres primary + replica + Adminer (needed for notebook 1)
docker compose up -d

# 2. Install Python deps into a local .venv managed by uv
uv sync
```

**Kernel selection.** Open any notebook in VS Code and pick the `.venv` kernel from the
kernel picker at the top-right. If `.venv` doesn't appear in the list, reload the
window: `Cmd+Shift+P` → "Reload Window".

## What's in the Docker stack?

| Service | Port | Purpose |
|---------|------|---------|
| `primary` | `5432` | Postgres 16 primary (accepts writes) |
| `replica` | `5433` | Postgres 16 streaming-replication replica (read-only) |
| `adminer` | `8080` | Web UI to inspect both databases |

### Adminer login

Open <http://localhost:8080> and log in with:

| Field    | Value                           |
|----------|---------------------------------|
| System   | `PostgreSQL`                    |
| Server   | `primary` *(or `replica`)*      |
| Username | `demo`                          |
| Password | `demo`                          |
| Database | `replication_demo`              |

> From Adminer's UI the server name is `primary` / `replica` (docker-internal network),
> **not** `localhost`.

## Tearing it down

```bash
docker compose down -v   # -v also removes the Postgres data volumes
```

## Key concepts covered

- **Leader–follower (primary–replica)** — one writer, many readers. The follower
  replays the leader's write-ahead log (WAL).
- **Synchronous replication** — primary waits for replicas before acking writes. Safe,
  but slow and fragile.
- **Asynchronous replication** — primary acks as soon as its own disk is written.
  Fast, but replicas lag — stale reads are possible.
- **Semi-synchronous replication** — primary waits for *at least one* replica.
  Pragmatic default for production.
- **Replication lag** — the time window where replicas don't yet have the latest
  write. Notebook 1 measures it live under load.
- **Failover & split-brain** — how a replica is promoted, what gets lost, and why
  fencing matters.
- **Read-your-own-writes consistency** — the most common UX bug caused by async
  replication, and a sticky-router fix (notebook 2).
- **Leaderless / quorum replication** — no designated writer; a write is "done" when
  **W** of **N** replicas ack, and a read is "done" when **R** of **N** answer.
- **The quorum rule**: if `W + R > N`, reads are guaranteed to overlap with the
  latest successful write.
- **Last-write-wins & read repair** — how Dynamo-style systems resolve concurrent
  writes and self-heal stale replicas (notebook 3).
- **Multi-leader replication** — a brief tour of when and why teams reach for it.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- Source material in `tools/scraper/designgurus/content/` under
  `grokking-system-design-fundamentals/` and `grokking-the-system-design-interview/`
