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

## Planned notebooks

> These are planned; files do not yet exist. Following the repo convention, each will be added as a separate numbered notebook (`NN_*.ipynb`) without renumbering earlier ones.

- `notebooks/01_split_log_into_segments.ipynb`
- `notebooks/02_segment_index_and_lookup.ipynb`

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
