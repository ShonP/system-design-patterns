# Segmented Log

> Part of `02-distributed-primitives/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Learning objectives

- Explain why unbounded logs are a problem (rotation, deletion, parallel IO).
- Split a log into segments with an index and truncate safely.

## Concepts covered

- Segment files
- Offset index
- Log rotation and retention
- Sparse indexes

## Setup

```bash
cd 02-distributed-primitives/segmented-log
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_single_file_log.ipynb`](./notebooks/01_single_file_log.ipynb) — the BAD design: a single ever-growing log file. Watch deletions become O(n).
- [`notebooks/02_segmented_log.ipynb`](./notebooks/02_segmented_log.ipynb) — split into segments, roll on size, drop old data with a single `unlink`.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
