# Facebook (core social graph)

> Part of the `07-object-oriented-design/` series. Includes runnable notebooks and references.

## Overview

OOD of the core of a social network: users, posts, friendships, comments, reactions, news feed.

## Concepts covered

- Symmetric friendship as a mirrored `set` (+ blocking cuts both ways)
- Post with comments and reactions (`dict[user_id → ReactionType]`, one per user)
- Privacy levels (`PUBLIC / FRIENDS / ONLY_ME`) via a single `can_see` function
- News feed derived from the friend graph (fanout-on-read)
- Bonus: fanout-on-write variant + when each strategy wins
- `ReactionType` as an enum, not a subclass hierarchy — with a bad→best comparison
- Mutual friends as set intersection

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
