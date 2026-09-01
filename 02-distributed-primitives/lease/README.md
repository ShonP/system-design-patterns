# Lease

> Part of `02-distributed-primitives/`. Pure-Python lab — no Docker required.

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
- [`notebooks/02_time_bounded_lease.ipynb`](./notebooks/02_time_bounded_lease.ipynb) — **BETTER:** leases with TTL and renewal; auto-recovery from crashes — then a clock-skew simulation that produces **two simultaneous holders**, and the two ways out (a bounded-skew safety margin, or a fencing token).
- [`notebooks/03_leader_election_auto_renew.ipynb`](./notebooks/03_leader_election_auto_renew.ipynb) — **REAL-WORLD:** three workers compete for leadership, the leader auto-renews via a background thread, crashes, and a standby takes over. Includes a matplotlib timeline, and a zombie leader that wakes up and gets its write **rejected** by a fencing check.

## When you need this — and when you don't

**Use a lease when** an owner might die holding the thing it owns. A plain lock cannot recover
from that; a lease releases itself. This is the basis of leader election in etcd, ZooKeeper
sessions, and Kubernetes `Lease` objects.

**Understand what it does and does not give you.** A lease bounds how long the cluster *waits*
before reassigning ownership. It does not bound how long the old owner keeps *believing* it is the
owner — notebook 2 produces two simultaneous holders using nothing but ordinary clock drift.

**So pair it with one of these, or you have no safety property at all:**
- a **fencing token** the resource checks — preferred, because it survives an unbounded pause; or
- an explicit **bounded clock assumption**: the holder self-expires early by more than the worst
  skew plus round trip you are willing to assume. Cheaper, and silently unsafe the moment reality
  exceeds the bound.

**Don't reach for a lease when** the work is idempotent and harmless to duplicate. Two workers
doing the same safe job is often much cheaper than getting mutual exclusion right.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
