# Write-Ahead Log (WAL)

> Part of `02-distributed-primitives/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Learning objectives

- Explain why a WAL is the foundation of crash-safe durability.
- Implement a minimal append-only log with fsync and replay after crash.
- Understand the ordering property: log entry persisted before state change.

## Concepts covered

- Append-only log
- fsync & durability
- Crash recovery via replay
- WAL vs redo/undo log

## Planned notebooks

> These are planned; files do not yet exist. Following the repo convention, each will be added as a separate numbered notebook (`NN_*.ipynb`) without renumbering earlier ones.

- `notebooks/01_build_a_minimal_wal.ipynb`
- `notebooks/02_crash_and_replay.ipynb`

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
