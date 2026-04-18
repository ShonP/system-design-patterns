# Merkle Trees

> Part of `02-distributed-primitives/`. Pure-Python lab — no Docker required.

## Learning objectives

- Build a Merkle tree from scratch and feel why one bit changes the root.
- Detect data differences between two replicas with `O(K log N)` traffic.
- Understand why anti-entropy systems (Cassandra, DynamoDB, Git) reach for Merkle.

## Concepts covered

- Hash trees and root hashes
- Anti-entropy / replica reconciliation
- Comparing full-scan vs Merkle-tree diffing

## Setup

```bash
cd 02-distributed-primitives/merkle-trees
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook).

## Notebooks

- [`notebooks/01_build_a_merkle_tree.ipynb`](./notebooks/01_build_a_merkle_tree.ipynb) — build a Merkle tree with `hashlib`; show one bit-flip moves the root.
- [`notebooks/02_replica_diff.ipynb`](./notebooks/02_replica_diff.ipynb) — full scan vs per-key hashes vs Merkle diff on two near-identical replicas; measure bytes sent.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
