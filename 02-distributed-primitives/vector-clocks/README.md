# Vector Clocks

> Part of `02-distributed-primitives/`. Pure-Python lab — no Docker required.

## Learning objectives

- See why wall-clock time fails to order distributed events.
- Implement Lamport clocks and discover why they lose information about concurrency.
- Implement vector clocks, detect concurrent updates, and verify the comparison really is a **partial** order (a total order is the classic bug).
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

## When you need this — and when you don't

**Use vector clocks when** concurrent writes are possible and silently dropping one is
unacceptable — carts, collaborative documents, anything a user would notice losing. They are the
only mechanism here that can tell "B overwrote A" apart from "A and B happened independently".

**Remember they only detect.** A vector clock reports a conflict; it has no opinion on how to
resolve it. Notebook 2 shows set-union quietly resurrecting a deleted item — the clocks were
right, the merge policy was wrong. Real Dynamo hands siblings back to the application for exactly
this reason.

**Prefer last-write-wins when** the data is naturally single-writer, or losing one of two
simultaneous writes is genuinely fine (a metric, a cached rendering). It is far simpler, and
Cassandra defaults to it.

**Prefer CRDTs when** you want automatic, order-independent merges and can express your data as a
type that commutes (counters, sets, sequences). More design work up front, no conflicts to resolve
later.

**Watch the size.** Vectors grow with the number of writers, so a client-generated vector can
balloon. Production systems prune old entries or use dotted version vectors to bound it.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
