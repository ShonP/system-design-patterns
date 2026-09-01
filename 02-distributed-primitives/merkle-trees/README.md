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

- [`notebooks/01_build_a_merkle_tree.ipynb`](./notebooks/01_build_a_merkle_tree.ipynb) — build a Merkle tree with `hashlib`; see one bit-flip move the root; learn why **leaf order**, **canonical serialization**, and **domain separation** matter.
- [`notebooks/02_inclusion_proofs.ipynb`](./notebooks/02_inclusion_proofs.ipynb) — prove a single leaf is in a tree using only `O(log N)` sibling hashes. Compare 🟥 send-everything vs 🟨 all-hashes vs 🟩 Merkle proof. The technique behind Bitcoin SPV and Certificate Transparency.
- [`notebooks/03_replica_diff.ipynb`](./notebooks/03_replica_diff.ipynb) — full scan vs per-key hashes vs Merkle walk on two near-identical replicas. **Counts the node comparisons** and checks the `O(K log N)` claim against a measured sweep from 500 to 32,000 keys. Uses a non-power-of-two dataset so padding is visible.

## Where Merkle trees show up in the real world

| System | Use of Merkle structures |
| --- | --- |
| **Apache Cassandra** | `nodetool repair` compares per-range Merkle trees between replicas. |
| **Amazon DynamoDB** | Background anti-entropy between partition replicas. |
| **Riak** | Active anti-entropy using per-partition hash trees. |
| **Git** | Commit / tree objects form a Merkle **DAG**. |
| **Bitcoin / Ethereum** | Block header stores a Merkle root; SPV wallets verify transactions with inclusion proofs. |
| **Certificate Transparency** | Append-only Merkle log of every TLS certificate (RFC 6962). |
| **IPFS** | Content-addressed Merkle **DAG** for files and directories. |
| **ZFS / btrfs** | Checksummed block trees (Merkle-like) detect bit-rot on disk. |

"Merkle **DAG**" generalizes the binary-tree idea to any directed acyclic graph of hashes — same core idea, different shape.

## When you need this — and when you don't

**Use a Merkle tree when** two parties hold large, *mostly identical* datasets and you need to
find the difference without shipping everything. Cost is `O(K log N)` in the number of
differences — and exactly one comparison when they already agree, which is the normal case.

**Also use one when** a small client must verify a single item against a huge dataset it cannot
download: an `O(log N)` inclusion proof plus a 32-byte root is the whole trust anchor. This is
Bitcoin SPV and Certificate Transparency.

**Don't bother when** the replicas usually differ a lot. Once `K` approaches `N` the walk
degenerates into a full scan with extra hashing on top — just ship the data.

**Also skip it when** the dataset is small enough to hash whole, or when you cannot pin down a
**canonical order and serialization**. Two honest replicas that iterate keys differently compute
different roots and will "disagree" forever.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
