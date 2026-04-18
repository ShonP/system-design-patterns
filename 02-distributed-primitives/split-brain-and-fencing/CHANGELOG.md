# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Split-Brain & Fencing` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
- Expanded `01_split_brain.ipynb`: added a concrete bank-balance example, step-by-step narration of the GC-pause + partition scenario, and a real-world systems table.
- Expanded `02_fencing_tokens.ipynb` into a BAD → BETTER → BEST progression: in-memory token (vulnerable to restart) vs persisted `highest_seen` on the resource with a `≤` check; fixed bank-balance example; clarified fencing vs idempotency.
- Added `03_stonith_and_resource_fencing.ipynb`: resource fencing (NFS ACL revoke) and STONITH (toy IPMI model); comparison table of how HDFS HA, Pacemaker, Patroni, Kafka, ZooKeeper/etcd layer the three fencing techniques.
