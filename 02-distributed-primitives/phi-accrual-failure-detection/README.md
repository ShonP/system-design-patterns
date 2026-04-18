# Phi Accrual Failure Detection

> Part of `02-distributed-primitives/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Learning objectives

- Understand why fixed-timeout failure detection is too rigid in practice.
- Compute a phi value from heartbeat-interval history and threshold on it.

## Concepts covered

- Heartbeat inter-arrival distribution (mean, std-dev, sliding window)
- Phi (φ) suspicion value via the Normal survival function `½·erfc(z/√2)`
- Warmup samples & `min_std` floor (why they matter)
- Adaptive thresholds: Cassandra's `φ=8`, Akka's `φ=12`
- Layered decisions from one signal: route-away → evict → fence
- Real-world nastiness: GC pauses, transient partitions, slow-but-alive nodes

## Setup

```bash
cd 02-distributed-primitives/phi-accrual-failure-detection
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_fixed_timeout_problem.ipynb`](./notebooks/01_fixed_timeout_problem.ipynb) — *feel* the pain: short timeouts → false positives, long timeouts → slow detection, with a picture for each.
- [`notebooks/02_phi_accrual_detector.ipynb`](./notebooks/02_phi_accrual_detector.ipynb) — implement the phi accrual detector (Cassandra/Akka flavor), watch φ rise smoothly, and see it survive a network blip that would fail a fixed-timeout detector.
- [`notebooks/03_real_world_cluster.ipynb`](./notebooks/03_real_world_cluster.ipynb) — run one detector per peer in a 5-node cluster and use three layered thresholds (`φ>3` route away, `φ>8` evict, `φ>12` fence) to ride out GC pauses and partitions while still catching real crashes.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
