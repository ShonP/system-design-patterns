# Read Repair

> Part of `02-distributed-primitives/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Learning objectives

- Use reads as an opportunity to reconcile stale replicas.
- Understand foreground (on-read) vs background (anti-entropy) repair.

## Concepts covered

- On-read reconciliation
- Last-write-wins vs vector-clock merge
- Anti-entropy repair

## Setup

```bash
cd 02-distributed-primitives/read-repair
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_stale_replica.ipynb`](./notebooks/01_stale_replica.ipynb) — **the problem**: trusting the first response returns stale data; quantify how often with varying replica/stale counts.
- [`notebooks/02_read_repair.ipynb`](./notebooks/02_read_repair.ipynb) — **the fix, bad → best**: read-one → quorum read → blocking read-repair → async read-repair → probabilistic read-repair (Cassandra-style).
- [`notebooks/03_anti_entropy_and_hints.ipynb`](./notebooks/03_anti_entropy_and_hints.ipynb) — **the full picture**: hinted handoff for short outages and a tiny Merkle-tree anti-entropy sweep for cold keys — complementary to read-repair.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
