# Write-Ahead Log (WAL)

> Part of `02-distributed-primitives/`. Pure-Python lab — no Docker required.

## Learning objectives

- Explain why a WAL is the foundation of crash-safe durability.
- Implement a minimal append-only log with `fsync` and replay after crash.
- Compare a WAL-based store with a snapshot-only store under simulated crashes.

## Concepts covered

- Append-only log
- `fsync` and durability
- Crash recovery via replay
- WAL vs whole-file snapshot

## Setup

```bash
cd 02-distributed-primitives/write-ahead-log
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). Reload the window if it doesn't appear: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_what_is_a_wal.ipynb`](./notebooks/01_what_is_a_wal.ipynb) — bad/better/best for a tiny key-value store: in-memory → snapshot file → WAL with replay.
- [`notebooks/02_crash_and_recovery.ipynb`](./notebooks/02_crash_and_recovery.ipynb) — actually crash a child process with `SIGKILL` and see how much each store loses.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
