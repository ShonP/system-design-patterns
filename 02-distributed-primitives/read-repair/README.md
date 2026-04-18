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

- [`notebooks/01_stale_replica.ipynb`](./notebooks/01_stale_replica.ipynb) — trusting the first response returns stale data when one replica is behind.
- [`notebooks/02_read_repair.ipynb`](./notebooks/02_read_repair.ipynb) — query several, return the freshest, and repair stale replicas inline. Compared with anti-entropy.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
