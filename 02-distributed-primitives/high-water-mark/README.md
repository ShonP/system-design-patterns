# High-Water Mark

> Part of `02-distributed-primitives/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Learning objectives

- Define the high-water mark as the last durably replicated offset.
- Reason about what a follower can safely expose to readers.

## Concepts covered

- High-water mark
- Replication offset
- Read visibility rules

## Setup

```bash
cd 02-distributed-primitives/high-water-mark
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_no_high_water_mark.ipynb`](./notebooks/01_no_high_water_mark.ipynb) — exposing the leader's tail leads to *acknowledged* writes being lost on failover.
- [`notebooks/02_with_high_water_mark.ipynb`](./notebooks/02_with_high_water_mark.ipynb) — track the highest quorum-replicated offset and only let clients see committed data.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
