# High-Water Mark

A **high-water mark (HWM)** is the highest log offset that a leader has safely replicated to a quorum of followers. Clients can only read entries at or below the HWM — anything above it is *tentative* and may be discarded after a leader change. This is the rule that prevents *acknowledged* writes from being lost on failover.

## Learning objectives

- Explain why exposing the leader's local tail can lose acknowledged writes.
- Compute the HWM from per-follower replicated offsets.
- See how followers learn the HWM (heartbeats / piggybacked metadata) and truncate divergent suffixes.
- Recognize the same pattern in Kafka, Raft, MongoDB, PostgreSQL, and ZooKeeper.

## Concepts covered

- Replicated logs and replication offsets
- Quorum-based commit
- High-water mark / `commitIndex` / ISR HWM
- Heartbeat propagation of the HWM
- Log truncation after a leadership change

## Setup

```bash
cd 02-distributed-primitives/high-water-mark
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_no_high_water_mark.ipynb`](./notebooks/01_no_high_water_mark.ipynb) — **bad**: exposing the leader's tail leads to acknowledged writes being lost on failover.
- [`notebooks/02_with_high_water_mark.ipynb`](./notebooks/02_with_high_water_mark.ipynb) — **better**: track the highest quorum-replicated offset and only let clients see committed data. Includes a matplotlib chart of leader-tail vs HWM.
- [`notebooks/03_heartbeats_and_truncation.ipynb`](./notebooks/03_heartbeats_and_truncation.ipynb) — **complete picture**: heartbeats propagate the HWM to followers (always one round trip behind), a rejoining node truncates its uncommitted tail, and an exhaustive check confirms no reachable failover can roll the HWM backwards.

## When you need this — and when you don't

**You need an HWM whenever** you acknowledge a write before every replica has it — i.e. any
leader-based replicated log. It is the line between "durable enough to promise" and "still
tentative", and without it a failover silently unmakes writes you already confirmed.

**You don't need it when** there is one copy of the data, or when every write is synchronously
replicated to *all* replicas before it is acknowledged — then the HWM is always the log tail, and
you have paid for that in availability instead.

**Watch out for follower reads.** A follower can only expose `min(its own log, the HWM it was
told)`, and the HWM it was told is always one round trip stale. That lag is why reading from a
follower is a weaker consistency mode, not a free scaling trick.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
