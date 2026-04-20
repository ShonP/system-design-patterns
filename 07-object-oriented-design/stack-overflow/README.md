# Stack Overflow

> Part of the `07-object-oriented-design/` series. Includes runnable notebooks and references.

## Overview

OOD of Stack Overflow.

## Concepts covered

- Clarifying questions, actors, use-cases, UML, SOLID check
- `User`, `Post`, `Question`, `Answer`, `Comment`, `Vote`
- Bad → Good → Best progression (god class → proper classes → enums/statuses)
- Tags + search (inverted index)
- Badges via the **observer** pattern
- Moderation (close / reopen / delete)
- Thread-safe voting (race reproduction + lock fix)
- Pluggable reputation rules via the **strategy** pattern

## Setup

```bash
cd 07-object-oriented-design/stack-overflow
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_class_design.ipynb`](./notebooks/01_class_design.ipynb) -- clarifying questions, actors, entities, UML, SOLID
- [`notebooks/02_implementation.ipynb`](./notebooks/02_implementation.ipynb) -- Bad → Good → Best implementation walkthrough
- [`notebooks/03_extensions.ipynb`](./notebooks/03_extensions.ipynb) -- tags/search, badges (observer), moderation, concurrency, strategy

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
