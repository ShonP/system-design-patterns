# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (repo-wide verification pass)
- **Fix**: notebooks 1-3 were structurally corrupt. Every line of their `source` arrays had lost its trailing newline, so the code was concatenated into gibberish (`import threadingimport timeimport os`) and no cell could run. 1,277 lines repaired across the three notebooks.
- **Fix**: `docker compose up --wait` could never succeed. The healthcheck runs `echo ruok | nc localhost 2181`, but ZooKeeper 3.5+ refuses four-letter-word commands that are not whitelisted -- the server answered *"ruok is not executed because it is not in the whitelist"*, so all three nodes stayed unhealthy forever. Added `ZOO_4LW_COMMANDS_WHITELIST` (this also fixes notebook 5's `mntr` probe) and gave the healthcheck a `start_period` so leader election has time to finish.
- Corrected the setup path in the README and notebooks (`cd deep-dives/zookeeper` → `03-technologies/coordination/zookeeper`).
- All 5 notebooks now execute end-to-end against the 3-node ensemble.

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
