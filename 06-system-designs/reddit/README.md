# Reddit

> Part of the `06-system-designs/` series. Includes runnable notebooks and references.

## Overview

Social news: subreddits, posts, votes, threaded comments, and hot ranking.

## Concepts covered

- Back-of-envelope QPS, storage and bandwidth — all derived from one set of constants
- **Hot ranking**, transcribed from Reddit's published formula
  (`sign*log10(|net|) + seconds/45000`), plus a runnable demo of the classic
  sign-placement mis-transcription and what it does to net-negative posts
- The other sorts with their real formulas: **Top**, **Controversial**
  (`magnitude ** balance`) and **Best** (Wilson score lower bound)
- **Vote fuzzing** — why displayed counts are deliberately wrong, and what it costs
- Denormalized vote counts vs. live aggregation (measured)
- Vote-counter contention: single row → sharded counters → Redis write-behind (measured)
- Threaded comment storage: adjacency list vs. materialized path vs. closure table

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
