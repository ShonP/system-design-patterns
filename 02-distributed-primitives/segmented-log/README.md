# Segmented Log

> Part of `02-distributed-primitives/`. Pure-Python lab — no Docker required.

## Learning objectives

- Explain why unbounded logs are a problem (rotation, deletion, parallel IO).
- Split a log into segments with an index and truncate safely.

## Concepts covered

- Segment files
- Offset index
- Log rotation and retention
- Sparse indexes
- Record framing: length + CRC, and truncate-at-first-bad-record recovery

## Setup

```bash
cd 02-distributed-primitives/segmented-log
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_single_file_log.ipynb`](./notebooks/01_single_file_log.ipynb) — the BAD design: a single ever-growing log file. Watch deletions become O(n).
- [`notebooks/02_segmented_log.ipynb`](./notebooks/02_segmented_log.ipynb) — BETTER: split into segments, roll on size, drop old data with a single `unlink`, read across segments.
- [`notebooks/03_sparse_index_and_recovery.ipynb`](./notebooks/03_sparse_index_and_recovery.ipynb) — BEST: add a sparse index (with a measured bound on scan length) and recover from a crash that left a torn write at the tail — including the torn write a length-only frame silently accepts, and the CRC that catches it.

## When you need this — and when you don't

**Segment your log when** it grows without bound and you need to delete or archive the oldest
part. Retention becomes `unlink` — O(1) per segment instead of rewriting every surviving byte.

**Also segment when** you want cheap parallelism, incremental backup, or the ability to freeze old
data: only the active segment is mutable, so everything behind it can be compressed, memory-mapped
or shipped to object storage untouched.

**Frame records with a length *and* a checksum.** Notebook 3 shows crash debris that a length-only
frame happily accepts as a record. Recovery must **truncate** at the first record that fails to
verify, never skip it — skipping leaves a hole in the middle of the log, which is strictly worse
than a short log because nothing downstream can detect it.

**Don't bother when** the log is bounded by construction (a fixed-size ring, a per-request audit
trail) or small enough to rewrite. The segment bookkeeping and the sparse index are real
complexity and buy nothing at that size.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
