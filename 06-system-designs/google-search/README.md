# Google Search

> Part of the `06-system-designs/` series. Includes runnable notebooks and references.

## Overview

Web-scale search: crawler, inverted index, ranking, sharding.

## Concepts covered

- Capacity estimation (back-of-envelope in code)
- End-to-end toy search (crawl → index → query)
- Retrieval progression: **linear scan → inverted index → TF-IDF → BM25**
- Tokenization pipeline: lowercase, stop-words, stemming
- Boolean operators, phrase queries (positional index), snippet generation
- Crawler: frontier politeness, URL canonicalization, Bloom-filter dedup, `robots.txt`
- Ranking: PageRank, blending BM25 × PageRank
- Query sharding: by term vs by document, fan-out + top-K merge
- LRU caching for hot queries

## Setup

```bash
cd 06-system-designs/google-search
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_requirements_and_architecture.ipynb`](./notebooks/01_requirements_and_architecture.ipynb) — Requirements & Architecture
- [`notebooks/02_data_and_api.ipynb`](./notebooks/02_data_and_api.ipynb) — Data Model & APIs
- [`notebooks/03_deep_dive.ipynb`](./notebooks/03_deep_dive.ipynb) — Deep Dive: Crawler, Ranking, Sharding

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
