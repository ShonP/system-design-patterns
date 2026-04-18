# Typeahead / Autocomplete

> Part of the `06-system-designs/` series. Includes runnable notebooks and references.

## Overview

Prefix-based suggestions at scale: trie + precomputed top-K + decaying trend.

## Concepts covered

- Trie with precomputed top-K at each node
- Batch-rebuild strategy for safe updates
- Ranking: frequency + trending + personalization
- Memory/sharding tradeoffs

## Setup

```bash
cd 06-system-designs/typeahead-autocomplete
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_requirements_and_architecture.ipynb`](./notebooks/01_requirements_and_architecture.ipynb) — Requirements & Architecture
- [`notebooks/02_data_and_api.ipynb`](./notebooks/02_data_and_api.ipynb) — Data Model & APIs
- [`notebooks/03_deep_dive.ipynb`](./notebooks/03_deep_dive.ipynb) — Deep Dive: Trie implementation, decay & updates

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
