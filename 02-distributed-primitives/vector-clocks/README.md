# Vector Clocks

> Part of `02-distributed-primitives/`. Pure-Python lab — no Docker required.

## Learning objectives

- Implement Lamport clocks and see why they lose information about concurrency.
- Implement vector clocks and detect concurrent updates.
- Explain how Dynamo-style systems use vector clocks to surface conflicts.

## Concepts covered

- Happens-before relation
- Lamport clocks vs vector clocks
- Concurrency detection and conflict surfacing

## Setup

```bash
cd 02-distributed-primitives/vector-clocks
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook).

## Notebooks

- [`notebooks/01_lamport_clocks.ipynb`](./notebooks/01_lamport_clocks.ipynb) — Lamport's scalar clock and where it falls short.
- [`notebooks/02_vector_clocks.ipynb`](./notebooks/02_vector_clocks.ipynb) — vector clocks: full causal order and concurrency detection.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
