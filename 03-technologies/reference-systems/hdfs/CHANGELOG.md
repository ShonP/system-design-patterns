# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20
- Rewrote `README.md` as a self-contained **paper guide** for *The Hadoop Distributed File System*
  (Shvachko, Kuang, Radia, Chansler — MSST 2010), replacing the scaffolding stub. Removed the
  "planned notebooks" section: this lab is documentation-only by design.
- Added full citation (the storageconference.us copy is dead, so the README links a working mirror
  plus the DOI), an ASCII architecture diagram, a core-design walkthrough (NameNode/DataNodes,
  image and journal, heartbeat-driven control plane, single-writer leases, write pipeline,
  rack-aware placement, block scanner and balancer), a decisions-and-costs table, a lineage section
  (HBase, the Hadoop ecosystem, ZooKeeper-based HA, displacement by object stores), verified
  cross-links, and a reading guide.
- Fact-checked against the paper text: 128 MB typical block size, replication factor three, 3-second
  heartbeats with a 10-minute death timeout, ~64 KB pipeline packets, one-hour hard lease limit,
  first replica local / second and third in another rack, and the Yahoo! deployment figures
  (25,000 servers, 25 PB, largest cluster 3500 nodes).
- Corrected the stub's implicit framing of HDFS HA: the published paper has **no** automatic
  NameNode failover — it names ZooKeeper-based failover as future work. Automatic failover arrived
  later, in Hadoop 2.

## 2026-04-18
- Scaffolded `Hdfs` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
