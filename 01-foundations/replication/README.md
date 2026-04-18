# Replication

> Part of `01-foundations/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Learning objectives

- Explain why we replicate data (availability, durability, read scalability).
- Compare leader-follower and peer-to-peer (multi-leader) replication.
- Reason about synchronous vs asynchronous replication and their consistency/availability tradeoffs.
- Understand quorum (N, R, W) and why R+W>N gives strongly consistent reads.

## Concepts covered

- Leader-follower (primary-replica) pattern
- Peer-to-peer / multi-leader replication
- Synchronous vs asynchronous replication; read replicas
- Replication lag and its effects
- Quorum: N, R, W; sloppy quorum
- Redundancy vs replication

## Planned notebooks

> These are planned; files do not yet exist. Following the repo convention, each will be added as a separate numbered notebook (`NN_*.ipynb`) without renumbering earlier ones.

- `notebooks/01_intro_leader_follower.ipynb`
- `notebooks/02_sync_vs_async_replication.ipynb`
- `notebooks/03_read_replicas_and_lag.ipynb`
- `notebooks/04_quorum_reads_and_writes.ipynb`

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
