# Collaborative Whiteboard

> Part of `06-system-designs/`. Runnable notebooks + references.

## Overview

Real-time collaborative drawing: CRDT, WebSocket.

## Concepts covered

- Requirements + a **runnable** capacity model (ingress vs fan-out egress, op-log growth)
- **OT vs CRDT, decided with code**: a working operational transform, the N² growth of its
  rule set, and the five things choosing a CRDT actually costs you
- Lamport clocks and a Last-Writer-Wins map CRDT
- The **lost update**: why whole-shape LWW silently discards a concurrent edit, and how
  per-field LWW fixes it (and what that costs)
- Offline merge across a partition
- Pub/Sub fan-out across WebSocket nodes
- Snapshots + op log (and why the snapshot index and the snapshot lamport are different numbers)
- Presence with TTL

## Setup

```bash
cd 06-system-designs/collaborative-whiteboard
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_requirements_and_architecture.ipynb`](./notebooks/01_requirements_and_architecture.ipynb) — Requirements & Architecture
- [`notebooks/02_data_and_api.ipynb`](./notebooks/02_data_and_api.ipynb) — Data Model & APIs
- [`notebooks/03_deep_dive.ipynb`](./notebooks/03_deep_dive.ipynb) — Deep Dive (runnable code)

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
