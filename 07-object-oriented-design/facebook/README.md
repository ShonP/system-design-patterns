# Facebook (core social graph)

> Part of the `07-object-oriented-design/` series. Includes runnable notebooks and references.

## Overview

OOD of the core of a social network: users, posts, friendships, comments, reactions, news feed.

## Concepts covered

- Symmetric friendship as a set
- Post with comments and reactions (dict, one per user)
- News feed derived from friend graph
- ReactionType as enum, not subclass

## Setup

```bash
cd 07-object-oriented-design/facebook
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_class_design.ipynb`](./notebooks/01_class_design.ipynb) — Domain model and class relationships
- [`notebooks/02_implementation.ipynb`](./notebooks/02_implementation.ipynb) — Working Python implementation you can run

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
