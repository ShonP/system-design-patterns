# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19
- Fixed stale `deep-dives/kafka` path references throughout README and notebooks (actual path is `03-technologies/messaging/kafka`).
- Fixed Notebook 1 setup text that incorrectly mentioned Zookeeper (our compose uses KRaft mode).
- Fixed Notebook 4 final recap table to correctly describe Notebook 3 and include Notebook 5.
- Added Notebook 5: Production Best Practices (bad → best progression covering schema validation, producer batching & compression, Dead Letter Queues, log retention & compaction, replication & `min.insync.replicas`, and consumer lag monitoring).

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
