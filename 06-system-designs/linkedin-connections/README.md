# LinkedIn Connections

> Part of `06-system-designs/`. Runnable notebooks + references.

## Overview

Social graph: connections, people-you-may-know, graph traversal.

## Concepts covered

- **Capacity estimation** for a billion-node social graph — edges, storage, read/write QPS with
  a peak factor, and the resulting shard count (disk-bound, not QPS-bound).
- **Edge storage patterns**: blob-in-a-row (bad) → single-row edge table (better) → **symmetric adjacency** (best, used by Facebook TAO).
- **Connection-request state machine** (pending → accepted / rejected / withdrawn) with pydantic validation.
- **BFS** for degrees of separation, and **bidirectional BFS** — verified against plain BFS
  (including the `max_depth` cut-off), benchmarked by *adjacency fetches* rather than by an
  unstable millisecond timing, and projected out to `b=500` where the win is ~10^5 at depth 4.
- **People You May Know**: naive live scoring → **Adamic–Adar** weighting (with the `1/log(d)`
  divide-by-zero landmine shown and fixed) → precomputed offline + KV serve.
- The **celebrity / hot-user** problem: hot shards, fat rows, skewed PYMK — and how to mitigate each.
- Pagination with cursors, idempotency keys, and why we separate `requests` from `edges`.

## Setup

```bash
cd 06-system-designs/linkedin-connections
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_requirements_and_architecture.ipynb`](./notebooks/01_requirements_and_architecture.ipynb) — Requirements, back-of-envelope, architecture, and the **bad → better → best** edge-storage progression (with runnable SQLite code).
- [`notebooks/02_data_and_api.ipynb`](./notebooks/02_data_and_api.ipynb) — Pydantic data model, the **request state machine** (with invariant tests), REST sketch, and the symmetric-edges SQLite table.
- [`notebooks/03_deep_dive.ipynb`](./notebooks/03_deep_dive.ipynb) — Algorithms deep dive: **bidirectional BFS** benchmarked on a 5k-node power-law graph, **Adamic–Adar PYMK**, offline precompute + KV serve, celebrity/hot-user mitigations.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
