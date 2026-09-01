# Read Repair

> Part of `02-distributed-primitives/`. Pure-Python lab — no Docker required.

## Learning objectives

- Use reads as an opportunity to reconcile stale replicas.
- Understand foreground (on-read) vs background (anti-entropy) repair.

## Concepts covered

- On-read reconciliation
- Last-write-wins vs vector-clock merge
- Anti-entropy repair

## Setup

```bash
cd 02-distributed-primitives/read-repair
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_stale_replica.ipynb`](./notebooks/01_stale_replica.ipynb) — **the problem**: trusting the first response returns stale data; quantify how often with varying replica/stale counts.
- [`notebooks/02_read_repair.ipynb`](./notebooks/02_read_repair.ipynb) — **the fix, bad → best**: read-one → quorum read → blocking read-repair → async read-repair → probabilistic read-repair (Cassandra-style). Repairs only the replicas the coordinator actually heard from, which is why cold keys never heal.
- [`notebooks/03_anti_entropy_and_hints.ipynb`](./notebooks/03_anti_entropy_and_hints.ipynb) — **the full picture**: hinted handoff for short outages and a tiny Merkle-tree anti-entropy sweep for cold keys — complementary to read-repair.

## When you need this — and when you don't

**Use read-repair when** replicas can diverge and reads already fan out to several of them. The
repair rides along on RPCs you are paying for anyway, so hot keys stay fresh essentially for free.

**Never rely on it alone.** It only fixes what someone reads. Cold keys — usually the majority —
are never touched and stay wrong indefinitely. Pair it with hinted handoff (short outages) and
anti-entropy (everything else); notebook 3 runs all three side by side.

**Choose blocking vs async deliberately.** Blocking repair guarantees the straggler is fixed
before you answer, at the cost of tail latency. Async keeps latency low and leaves a window in
which another coordinator can still read the stale value.

**Not needed when** every write goes through consensus (etcd, Spanner, CockroachDB): committed
replicas cannot disagree, so there is nothing to reconcile.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
