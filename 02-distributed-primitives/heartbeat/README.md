# Heartbeat

> Part of `02-distributed-primitives/`. Pure-Python lab — no Docker required.

## Learning objectives

- Implement heartbeat-based liveness detection.
- Reason about the false-positive vs detection-delay trade-off of fixed timeouts.
- Replace the hard threshold with a smooth, adaptive **phi accrual** suspicion score.

## Concepts covered

- Heartbeat interval & timeout
- False positives vs detection delay
- Phi accrual failure detector (Hayashibara) — used by Cassandra, Akka

## Setup

```bash
cd 02-distributed-primitives/heartbeat
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook).

## Notebooks

- [`notebooks/01_fixed_heartbeat.ipynb`](./notebooks/01_fixed_heartbeat.ipynb) — fixed-interval heartbeat with a hard timeout; sweep timeouts to feel the trade-off.
- [`notebooks/02_phi_accrual.ipynb`](./notebooks/02_phi_accrual.ipynb) — phi accrual detector that learns the network's cadence; plot suspicion over time.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
