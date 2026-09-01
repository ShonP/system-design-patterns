# Heartbeat

> Part of `02-distributed-primitives/`. Pure-Python lab — no Docker required.

## Learning objectives

- Implement heartbeat-based liveness detection.
- Reason about the false-positive vs detection-delay trade-off of fixed timeouts.
- Replace the hard threshold with a smooth, adaptive **phi accrual** suspicion score.

## Concepts covered

- Heartbeat interval & timeout
- "k missed beats" rule
- False positives vs detection delay
- Phi accrual failure detector (Hayashibara) — used by Cassandra, Akka
- Push vs pull heartbeats; central monitor vs gossip
- Fencing & split-brain (why detection alone is not enough)

## Setup

```bash
cd 02-distributed-primitives/heartbeat
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook).

## Notebooks

- [`notebooks/01_fixed_heartbeat.ipynb`](./notebooks/01_fixed_heartbeat.ipynb) — fixed-interval heartbeat with a hard timeout; sweep timeouts and "k missed beats" rules to feel the false-positive vs detection-delay trade-off.
- [`notebooks/02_phi_accrual.ipynb`](./notebooks/02_phi_accrual.ipynb) — phi accrual detector that learns the network's cadence; side-by-side comparison with fixed timeout under a realistic network blip.
- [`notebooks/03_real_world.ipynb`](./notebooks/03_real_world.ipynb) — push vs pull, central monitor vs gossip, and why detection without **fencing** can corrupt your data.

## When you need this — and when you don't

**Use heartbeats when** you need to know a peer is *alive* and you control both ends. They are
the cheapest liveness signal there is: one small message per interval, no round trip.

**Use pull health checks instead when** you need to know a peer is *useful*, not merely running —
a load balancer wants "can you serve a query", which a heartbeat cannot answer.

**Know the limit before you build on it:** no failure detector can distinguish a crashed node
from a slow one. Every timeout is a bet, and notebook 1 measures the price of both sides of it.
Phi accrual (notebook 2) changes the units of the bet; it does not remove it.

**Never act destructively on detection alone.** A false positive that triggers a failover is how
you get two leaders. Pair detection with fencing — see `lease` and `split-brain-and-fencing`.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
