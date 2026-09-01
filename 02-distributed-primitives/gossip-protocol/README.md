# Gossip Protocol

> Part of `02-distributed-primitives/`. Pure-Python lab — no Docker required.

## Learning objectives

- Simulate an epidemic-style gossip protocol and **measure** convergence time against fanout and cluster size.
- Understand why gossip scales as `O(log N)` rounds regardless of cluster size.
- Know where gossip is used in real systems (Cassandra, DynamoDB, Consul, Serf).

## Concepts covered

- Epidemic / push gossip
- Fanout vs convergence time
- Robustness to message loss
- Push vs pull vs push-pull gossip
- Anti-entropy with `(generation, heartbeat)` versioning (Cassandra style)
- Failure detection by watching heartbeat counters
- Seed nodes and avoiding logical partitions

## Setup

```bash
cd 02-distributed-primitives/gossip-protocol
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook).

## Notebooks

- [`notebooks/01_what_is_gossip.ipynb`](./notebooks/01_what_is_gossip.ipynb) — central broadcast vs push gossip; convergence S-curve, fanout sweep, robustness to message loss.
- [`notebooks/02_push_pull_and_failure_detection.ipynb`](./notebooks/02_push_pull_and_failure_detection.ipynb) — push vs pull vs push-pull; Cassandra-style heartbeat/generation versioning; failure detection via gossip; seed-node bootstrap.

## When you need this — and when you don't

**Use gossip when** you need cluster-wide state (membership, health, schema version) with no
coordinator to fail, and you can tolerate a view that is *eventually* consistent. It earns its
keep past a few dozen nodes, where a central monitor becomes both a bottleneck and a SPOF.

**Don't use gossip when** you need agreement rather than dissemination. Gossip converges; it does
not decide. Leader election, distributed locks, and anything with a correctness invariant need
consensus — see the `quorum` and `split-brain-and-fencing` labs.

**Also skip it when** the cluster is small and static. Ten nodes reporting to one API server is
simpler to operate and easier to debug; gossip's constant background chatter and
eventually-consistent membership are real operational costs.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
