# 02 Distributed Primitives

Low-level building blocks that distributed systems are made of. Each sub-lab
focuses on a single primitive, drawn from the patterns catalogue in
*Grokking the Advanced System Design Interview*, *Designing Data-Intensive
Applications*, and the canonical papers.

Every lab follows the **bad → better → best** progression: start with a naive
implementation, see exactly *how* and *why* it breaks, then build up to the
production form.

## Labs in this section

| Lab | Notebooks | Primitive |
|---|---:|---|
| [`write-ahead-log/`](./write-ahead-log/) | 4 | Append-only log that makes state changes crash-safe |
| [`segmented-log/`](./segmented-log/) | 3 | Log split into manageable segments with an index |
| [`high-water-mark/`](./high-water-mark/) | 3 | Last durably replicated offset visible to readers |
| [`lease/`](./lease/) | 3 | Time-bounded ownership (used for leases, leader election) |
| [`heartbeat/`](./heartbeat/) | 3 | Liveness signal between nodes |
| [`gossip-protocol/`](./gossip-protocol/) | 2 | Epidemic-style membership / state dissemination |
| [`phi-accrual-failure-detection/`](./phi-accrual-failure-detection/) | 3 | Adaptive failure detection from heartbeat history |
| [`split-brain-and-fencing/`](./split-brain-and-fencing/) | 3 | Handling two-leader situations with fencing tokens |
| [`vector-clocks/`](./vector-clocks/) | 2 | Causality tracking and conflict detection |
| [`merkle-trees/`](./merkle-trees/) | 3 | Efficient replica reconciliation (anti-entropy) |
| [`hinted-handoff/`](./hinted-handoff/) | 3 | Writes survive brief node outages via hints |
| [`read-repair/`](./read-repair/) | 3 | Reconcile stale replicas during reads |
| [`checksum/`](./checksum/) | 3 | Data integrity detection (CRC vs cryptographic hashes) |
| [`quorum/`](./quorum/) | 3 | Majority-based reads and writes (N, R, W) |

All labs follow the same skeleton: `README.md`, `notebooks/`,
`references/designgurus.md`, `CHANGELOG.md`.

See also:
- [`../docs/restructure-proposal.md`](../docs/restructure-proposal.md) — overall repo structure
- [`../docs/content-map.md`](../docs/content-map.md) — lesson → lab mapping
