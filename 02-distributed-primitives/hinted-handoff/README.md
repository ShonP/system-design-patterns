# Hinted Handoff

> Part of `02-distributed-primitives/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Learning objectives

- Explain how writes survive brief node outages via hints on other nodes.
- Reason about hint expiry and the risk of data loss.

## Concepts covered

- Temporary replica substitution
- Hint log
- Hint TTL

## Setup

```bash
cd 02-distributed-primitives/hinted-handoff
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_writes_lost_when_node_down.ipynb`](./notebooks/01_writes_lost_when_node_down.ipynb) — forward-and-forget loses every write a downed replica missed.
- [`notebooks/02_hinted_handoff.ipynb`](./notebooks/02_hinted_handoff.ipynb) — coordinator queues hints and replays them when the replica recovers.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
