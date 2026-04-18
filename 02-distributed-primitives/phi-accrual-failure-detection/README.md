# Phi Accrual Failure Detection

> Part of `02-distributed-primitives/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Learning objectives

- Understand why fixed-timeout failure detection is too rigid in practice.
- Compute a phi value from heartbeat-interval history and threshold on it.

## Concepts covered

- Heartbeat inter-arrival distribution
- Phi value
- Adaptive thresholds

## Setup

```bash
cd 02-distributed-primitives/phi-accrual-failure-detection
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_fixed_timeout_problem.ipynb`](./notebooks/01_fixed_timeout_problem.ipynb) — short timeouts → false positives, long ones → slow detection.
- [`notebooks/02_phi_accrual_detector.ipynb`](./notebooks/02_phi_accrual_detector.ipynb) — adaptive suspicion that learns the network's cadence (Cassandra/Akka).

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
