# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20
- Rewrote `README.md` as a self-contained **paper guide** for *Dynamo: Amazon's Highly Available
  Key-value Store* (DeCandia et al. — SOSP '07), replacing the scaffolding stub. Removed the
  "planned notebooks" section: this lab is documentation-only by design.
- Added full citation with the canonical PDF, an ASCII ring/preference-list diagram, a core-design
  walkthrough (consistent hashing with virtual nodes, sloppy quorums, hinted handoff, vector clocks
  with read-time reconciliation, Merkle-tree anti-entropy, gossip membership, zero-hop routing, and
  the 99.9th-percentile SLA framing), a decisions-and-costs table, a lineage section, verified
  cross-links to the primitives labs, and a reading guide.
- Fact-checked against the paper text: `(N,R,W) = (3,2,2)` as the common configuration, vector-clock
  truncation at a threshold of about 10 pairs, clients polling membership roughly every 10 seconds,
  the 300 ms / 99.9% / 500 rps example SLA, and the 99.9995% success figure.
- Added an explicit warning that **Dynamo and Amazon DynamoDB are different systems**, with a
  pointer to the USENIX ATC 2022 DynamoDB paper.

## 2026-04-18
- Scaffolded `Dynamo` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
