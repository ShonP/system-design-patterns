# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Split-Brain & Fencing` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
- Expanded `01_split_brain.ipynb`: added a concrete bank-balance example, step-by-step narration of the GC-pause + partition scenario, and a real-world systems table.
- Expanded `02_fencing_tokens.ipynb` into a BAD → BETTER → BEST progression: in-memory token (vulnerable to restart) vs persisted `highest_seen` on the resource with a `≤` check; fixed bank-balance example; clarified fencing vs idempotency.
- Added `03_stonith_and_resource_fencing.ipynb`: resource fencing (NFS ACL revoke) and STONITH (toy IPMI model); comparison table of how HDFS HA, Pacemaker, Patroni, Kafka, ZooKeeper/etcd layer the three fencing techniques.

## 2026-08-20
- **Bug fix (semantics):** the "BEST" fencing rule rejected `token <= highest_seen`, which fences
  the *current* leader out after its own first write — a leader holds one token for its entire
  term and writes many times under it. The rule is now `token < highest_seen`, matching Kafka's
  controller epoch, ZooKeeper's zxid and HDFS NameNode generations.
- The replay protection that `<=` was standing in for is now a separate, explicit mechanism
  (request ids), so fencing and idempotency are shown doing their different jobs. This also
  resolves a contradiction with the lab's own "fencing vs idempotency" note.
- Replaced print-only checks with assertions: the stale write is rejected, `highest_seen` does
  not move on a rejected write, nothing from a fenced leader reaches the log, the in-memory
  version really does regress after a restart, and the bank balance ends at exactly 3000.
