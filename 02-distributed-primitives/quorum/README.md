# Quorum (N, R, W)

> Part of `02-distributed-primitives/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Learning objectives

- Reason about why R + W > N gives strongly consistent reads in a Dynamo-style system.
- Compute the availability/consistency trade-offs of different N/R/W choices.

## Concepts covered

- N, R, W parameters
- Strict vs sloppy quorum
- Consistency/availability trade-offs

## Setup

```bash
cd 02-distributed-primitives/quorum
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_quorum_basics.ipynb`](./notebooks/01_quorum_basics.ipynb) — implement W/R quorums, see why W+R>N gives strong consistency, and watch eventual consistency surface stale reads.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
