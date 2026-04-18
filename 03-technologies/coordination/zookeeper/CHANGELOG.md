# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
- Added Notebook 04 (`04_service_discovery.ipynb`): bad → better → best walkthrough of
  service discovery using ephemeral child nodes and `ChildrenWatch`, including a crash
  demo and a note on real-world users (Kafka pre-KRaft, HBase, Solr).
- Added Notebook 05 (`05_sessions_watches_and_when_not_to_use.ipynb`): session lifecycle
  (`CONNECTED` / `SUSPENDED` / `LOST`), the three rules of watches, ZAB quorum sizing,
  and guidance on when ZooKeeper is the wrong tool (vs etcd, Consul, Kafka, a real DB).
- Added a "watch the predecessor" gotcha cell to Notebook 02 explaining how kazoo's
  `Election` and `Lock` recipes avoid thundering herd.
- Added a "watches are re-read signals, not an event log" gotcha cell to Notebook 03
  covering one-shot semantics, thin events, and notification collapsing.
