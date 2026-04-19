# Vector Clocks

> Part of `02-distributed-primitives/`. Pure-Python lab — no Docker required.

## Learning objectives

- See why wall-clock time fails to order distributed events.
- Implement Lamport clocks and discover why they lose information about concurrency.
- Implement vector clocks and detect concurrent updates.
- Build a Dynamo-style shopping cart that detects **and resolves** conflicting writes.
- Know when real systems pick vector clocks, last-write-wins, or CRDTs.

## Concepts covered

- Clock drift & why `time.time()` can't order distributed events
- Happens-before relation (`→`)
- Lamport clocks vs vector clocks
- Concurrency detection and conflict surfacing
- Detect-vs-resolve: merge policies are application-defined
- Trade-offs: Dynamo/Riak (vector clocks) vs Cassandra (LWW) vs CRDTs

## Setup

```bash
cd 02-distributed-primitives/vector-clocks
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook).

## Notebooks

- [`notebooks/01_lamport_clocks.ipynb`](./notebooks/01_lamport_clocks.ipynb) — Wall-clock pitfalls, Lamport's scalar clock, space-time diagram, and where it falls short.
- [`notebooks/02_vector_clocks.ipynb`](./notebooks/02_vector_clocks.ipynb) — Vector clocks, concurrency detection, and a runnable Dynamo-style shopping-cart merge (LWW vs vector-clock).

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
