# Key-Value Store

> Part of the `06-system-designs/` series. Includes runnable notebooks and references.

## Overview

Distributed KV store: partitioning, replication, tunable consistency.

## Concepts covered

- Back-of-envelope sizing: QPS, storage with replication + LSM overhead, node count
  (disk-bound vs write-bound), and east-west replication bandwidth
- Naive `hash % N` vs consistent hashing (with runnable comparison)
- Virtual nodes: the load-balance win **and** what they cost (gossip, blast radius, no range scans)
- Replica placement on the ring (preference lists) and replication factor N
- Tunable W/R quorums, with a simulator that **measures** stale reads and unavailability
  separately — showing `R+W>N` is about correctness, not availability
- Versioning: no version (silent loss) → CAS (visible rejection) → **last-write-wins losing an
  acknowledged write to clock skew** → vector clocks with siblings
- Storage engine sketch: WAL + memtable + SSTables (toy LSM-tree)
- Anti-entropy via Merkle trees (runnable diff)
- Hinted handoff and read repair

## Setup

```bash
cd 06-system-designs/key-value-store
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_requirements_and_architecture.ipynb`](./notebooks/01_requirements_and_architecture.ipynb) — Requirements & Architecture
- [`notebooks/02_data_and_api.ipynb`](./notebooks/02_data_and_api.ipynb) — Data Model & APIs
- [`notebooks/03_deep_dive.ipynb`](./notebooks/03_deep_dive.ipynb) — Deep Dive: Consistent hashing, Quorums, Anti-entropy

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
