# Phi Accrual Failure Detection

> Part of `02-distributed-primitives/`. Pure-Python lab — no Docker required.

## Learning objectives

- Understand why fixed-timeout failure detection is too rigid in practice.
- Compute a phi value from heartbeat-interval history and threshold on it.

## Concepts covered

- Heartbeat inter-arrival distribution (mean, std-dev, sliding window)
- Phi (φ) suspicion value via the Normal survival function `½·erfc(z/√2)`
- Warmup samples & `min_std` floor (why they matter)
- Adaptive thresholds: Cassandra's `φ=8`, Akka's `φ=12` — and what they cost on a lossy link — and what they cost on a lossy link
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
- [`notebooks/02_phi_accrual_detector.ipynb`](./notebooks/02_phi_accrual_detector.ipynb) — implement the phi accrual detector (Cassandra/Akka flavor), verify φ against the paper's formula, and watch a 1.5s network blip push it **past** Cassandra's default threshold — then tune `min_std` so it doesn't, without losing crash detection.
- [`notebooks/03_real_world_cluster.ipynb`](./notebooks/03_real_world_cluster.ipynb) — run one detector per peer in a 5-node cluster and use three layered thresholds (`φ>3` route away, `φ>8` evict, `φ>12` fence) to ride out GC pauses and partitions while still catching real crashes.

## When you need this — and when you don't

**Use phi accrual when** one heartbeat stream has to serve several decisions with different costs
of being wrong — reroute traffic cheaply, evict carefully, fence almost never. A boolean timeout
forces every caller to share one answer; a continuous suspicion value does not.

**Also use it when** peers legitimately differ in cadence. A node that beats every 1.5s instead of
1.0s is dead forever to a fixed timeout and completely fine to phi, which learns its rhythm.

**Be clear about what it does not do.** It is not self-tuning and it does not abolish false
positives — notebook 2 shows a 1.5s packet-loss burst pushing φ past Cassandra's default threshold
on a perfectly healthy node. You now tune a threshold and `min_std` instead of a timeout: better
units, same Pareto curve.

**Skip it when** a fixed timeout is genuinely adequate: a stable LAN, uniform nodes, one consumer
of the signal. The extra machinery buys nothing there.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
