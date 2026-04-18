# Lease

> Part of `02-distributed-primitives/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Learning objectives

- Distinguish a lease from a lock (time-bounded ownership).
- Understand lease-based leader election and why it needs clock assumptions.
- See how auto-renewal (background thread / keep-alive) is used in real systems like etcd, Kubernetes, ZooKeeper.
- Learn about fencing tokens and why they prevent split-brain after a zombie leader wakes up.

## Concepts covered

- Lease duration & renewal (`renew interval ≈ TTL / 3` rule of thumb)
- Lease-based leadership & failover window
- Fencing tokens for correctness under clock skew / GC pauses
- Clock drift considerations

## Setup

```bash
cd 02-distributed-primitives/lease
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_lock_without_expiry.ipynb`](./notebooks/01_lock_without_expiry.ipynb) — **BAD:** a holder crashing locks everyone out forever.
- [`notebooks/02_time_bounded_lease.ipynb`](./notebooks/02_time_bounded_lease.ipynb) — **BETTER:** leases with TTL and renewal; auto-recovery from crashes.
- [`notebooks/03_leader_election_auto_renew.ipynb`](./notebooks/03_leader_election_auto_renew.ipynb) — **REAL-WORLD:** three workers compete for leadership, the leader auto-renews via a background thread, crashes, and a standby takes over. Includes a matplotlib timeline and a fencing token to prevent split-brain.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
