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

1. [`notebooks/01_quorum_basics.ipynb`](./notebooks/01_quorum_basics.ipynb) —
   bad→best progression: single node → `W=R=1` (stale reads) → `W+R>N`
   (strong consistency). Includes the pigeonhole intuition.
2. [`notebooks/02_tuning_and_tradeoffs.ipynb`](./notebooks/02_tuning_and_tradeoffs.ipynb) —
   availability vs quorum size (binomial model + matplotlib plot) and a small
   tail-latency simulation.
3. [`notebooks/03_sloppy_quorum_and_repair.ipynb`](./notebooks/03_sloppy_quorum_and_repair.ipynb) —
   Dynamo-style sloppy quorum, hinted handoff, read repair, and a note on
   LWW vs vector clocks vs CRDTs.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
