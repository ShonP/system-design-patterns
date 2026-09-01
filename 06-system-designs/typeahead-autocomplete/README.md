# Typeahead / Autocomplete

> Part of the `06-system-designs/` series. Includes runnable notebooks and references.

## Overview

Prefix-based suggestions at scale: trie + precomputed top-K + decaying trend.

## Concepts covered

- Back-of-envelope sizing for a per-keystroke service (QPS, edge-cache effect, index size in GB)
- Input normalization (lowercase, unicode folding, whitespace)
- Three implementations: linear scan → sorted + bisect → trie with precomputed top-K
- Benchmarks on **short vs long prefixes** — why query-time ranking collapses
  exactly on the hot prefixes, and therefore why we precompute
- Measuring the trie's real memory, and capping the top-K cache by depth
  (~80% smaller, identical answers)
- FastAPI + Pydantic `/suggest` and `/log` endpoints (exercised in-notebook via `TestClient`)
- Freshness via a decaying counter in the aggregator (not the serving trie)
- Optional typo tolerance via edit-distance-1 fallback
- Memory / sharding / replication tradeoffs, sized from the measured node count
- Real-world case studies: Google, YouTube, Amazon, Elasticsearch completion suggester, and the Redis sorted-set trick (reproduced in pure Python)

## Setup

```bash
cd 06-system-designs/typeahead-autocomplete
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_requirements_and_architecture.ipynb`](./notebooks/01_requirements_and_architecture.ipynb) — Requirements, capacity estimate, naïve baseline, architecture
- [`notebooks/02_data_and_api.ipynb`](./notebooks/02_data_and_api.ipynb) — Data model, Pydantic schemas, runnable FastAPI `/suggest` + `/log`
- [`notebooks/03_deep_dive.ipynb`](./notebooks/03_deep_dive.ipynb) — bad → best progression (scan → bisect → trie), benchmarks, decay, optional fuzzy fallback
- [`notebooks/04_real_world.ipynb`](./notebooks/04_real_world.ipynb) — Case studies + runnable Redis-style sorted-set autocomplete

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
