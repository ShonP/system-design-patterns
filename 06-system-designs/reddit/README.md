# Reddit

> Part of the `06-system-designs/` series. Includes runnable notebooks and references.

## Overview

Social news: subreddits, posts, votes, threaded comments, and hot ranking.

## Concepts covered

- Hot-ranking formula (log + time bonus)
- Denormalized vote counts
- Sharded counters for hot posts
- Threaded comment storage (parent_id + materialized path)

## Setup

```bash
cd 06-system-designs/reddit
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_requirements_and_architecture.ipynb`](./notebooks/01_requirements_and_architecture.ipynb) — Requirements & Architecture
- [`notebooks/02_data_and_api.ipynb`](./notebooks/02_data_and_api.ipynb) — Data Model & APIs
- [`notebooks/03_deep_dive.ipynb`](./notebooks/03_deep_dive.ipynb) — Deep Dive: Hot ranking, sharded counters, comment trees

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
