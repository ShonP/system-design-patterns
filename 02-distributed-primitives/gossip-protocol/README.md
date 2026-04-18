# Gossip Protocol

> Part of `02-distributed-primitives/`. Pure-Python lab — no Docker required.

## Learning objectives

- Simulate an epidemic-style gossip protocol and observe convergence time.
- Understand why gossip scales as `O(log N)` rounds regardless of cluster size.
- Know where gossip is used in real systems (Cassandra, DynamoDB, Consul, Serf).

## Concepts covered

- Epidemic / push gossip
- Fanout vs convergence time
- Anti-entropy and membership dissemination

## Setup

```bash
cd 02-distributed-primitives/gossip-protocol
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook).

## Notebooks

- [`notebooks/01_what_is_gossip.ipynb`](./notebooks/01_what_is_gossip.ipynb) — central broadcast vs gossip; convergence S-curve and fanout sweep.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
