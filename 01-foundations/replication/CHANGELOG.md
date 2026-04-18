# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Replication` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added notebooks 1–3: leader–follower basics, sync vs async, quorum reads/writes.
- QA pass: every notebook now runs end-to-end without errors.
- Notebook 1: added "lag under load" measurement, failover discussion (split-brain
  fencing), and a real-world examples table (RDS, GitHub, Heroku, Mongo, Redis).
- Notebook 2: added the **read-your-own-writes** pattern as an explicit
  bad-practice → best-practice progression, with a sticky-router implementation.
  Added a real-world examples table (Twitter timeline, Stripe, Postgres Multi-AZ,
  GitHub semi-sync, Kafka `acks=all`).
- Notebook 3: added concurrent-writes / last-write-wins demo, a working
  read-repair `RepairingCluster` subclass, a multi-leader-replication mention, and
  a real-world examples table (Cassandra, DynamoDB, Riak, Scylla, etcd).
- Notebook 3 §3 made deterministic so the explanatory text matches the output.
