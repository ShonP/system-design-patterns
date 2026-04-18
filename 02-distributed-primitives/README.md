#  Distributed Primitives02 

Low-level building blocks that distributed systems are made of.
Each sub-lab focuses on a single primitive, drawn from the patterns catalogue in
*Grokking the Advanced System Design Interview* and similar sources.

## Labs in this section

| Lab | Primitive |
|---|---|
| [`write-ahead-log/`](./write-ahead-log/) | Append-only log that makes state changes crash-safe |
| [`segmented-log/`](./segmented-log/) | Log split into manageable segments with an index |
| [`high-water-mark/`](./high-water-mark/) | Last durably replicated offset visible to readers |
| [`lease/`](./lease/) | Time-bounded ownership (used for leases, leader election) |
| [`heartbeat/`](./heartbeat/) | Liveness signal between nodes |
| [`gossip-protocol/`](./gossip-protocol/) | Epidemic-style membership / state dissemination |
| [`phi-accrual-failure-detection/`](./phi-accrual-failure-detection/) | Adaptive failure detection from heartbeat history |
| [`split-brain-and-fencing/`](./split-brain-and-fencing/) | Handling two-leader situations with fencing tokens |
| [`vector-clocks/`](./vector-clocks/) | Causality tracking and conflict detection |
| [`merkle-trees/`](./merkle-trees/) | Efficient replica reconciliation (anti-entropy) |
| [`hinted-handoff/`](./hinted-handoff/) | Writes survive brief node outages via hints |
| [`read-repair/`](./read-repair/) | Reconcile stale replicas during reads |
| [`checksum/`](./checksum/) | Data integrity detection (CRC vs cryptographic hashes) |
| [`quorum/`](./quorum/) | Majority-based reads and writes (N, R, W) |

All labs follow the same skeleton: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
Notebooks will be added  see each lab's README for the notebook plan.incrementally 

See also:
- [`../docs/restructure-proposal.md`](../docs/restructure-proposal. overall repo structuremd) 
 lab mapping
