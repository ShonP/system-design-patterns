# Write-Ahead Log (WAL)

> Part of `02-distributed-primitives/`. Pure-Python lab — no Docker required.

## Learning objectives

- Explain why a WAL is the foundation of crash-safe durability.
- Implement a minimal append-only log with `fsync` and replay after crash.
- Compare a WAL-based store with a snapshot-only store under simulated crashes.
- Keep recovery fast with periodic **checkpoints** and log truncation.
- Tune the durability / throughput trade-off with **group commit**.

## Concepts covered

- Append-only log
- `fsync` and durability
- Crash recovery via replay
- Torn writes and why newline-delimited JSON is self-healing
- WAL vs whole-file snapshot
- Checkpoints and log compaction (the `snapshot + tail-of-log` recovery pattern)
- Group commit (batched `fsync`) and the durability/throughput trade-off

## Setup

```bash
cd 02-distributed-primitives/write-ahead-log
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). Reload the window if it doesn't appear: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_what_is_a_wal.ipynb`](./notebooks/01_what_is_a_wal.ipynb) — bad/better/best for a tiny key-value store: in-memory → snapshot file → WAL with replay, plus a torn-write demo.
- [`notebooks/02_crash_and_recovery.ipynb`](./notebooks/02_crash_and_recovery.ipynb) — actually crash a child process with `SIGKILL` and see how much each store loses.
- [`notebooks/03_checkpoints_and_compaction.ipynb`](./notebooks/03_checkpoints_and_compaction.ipynb) — add periodic checkpoints so recovery stays fast even when the log has grown huge.
- [`notebooks/04_fsync_and_group_commit.ipynb`](./notebooks/04_fsync_and_group_commit.ipynb) — benchmark `fsync` cost and implement group commit, the same knob real databases expose.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
