# LinkedIn Connections

> Part of `06-system-designs/`. Runnable notebooks + references.

## Overview

Social graph: connections, people-you-may-know, graph traversal.

## Concepts covered

- **Capacity estimation** for a billion-node social graph.
- **Edge storage patterns**: blob-in-a-row (bad) → single-row edge table (better) → **symmetric adjacency** (best, used by Facebook TAO).
- **Connection-request state machine** (pending → accepted / rejected / withdrawn) with pydantic validation.
- **BFS** for degrees of separation, and **bidirectional BFS** (5 orders of magnitude faster at depth 4).
- **People You May Know**: naive live scoring → **Adamic–Adar** weighting → precomputed offline + KV serve.
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
