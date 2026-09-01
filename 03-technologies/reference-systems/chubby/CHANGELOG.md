# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20
- Rewrote `README.md` as a self-contained **paper guide** for *The Chubby lock service for
  loosely-coupled distributed systems* (Mike Burrows — OSDI '06), replacing the scaffolding stub.
  Removed the "planned notebooks" section: this lab is documentation-only by design.
- Added full citation with the canonical PDF, an ASCII cell/session diagram, a core-design
  walkthrough (five-replica cell with a master lease, the `/ls/cell/...` namespace, permanent vs.
  ephemeral nodes, advisory reader/writer locks, sequencers and lock-delay, sessions and KeepAlives,
  jeopardy and the grace period, and invalidation-based consistent caching), a decisions-and-costs
  table, a lineage section (ZooKeeper, etcd, Consul, fencing tokens, "Paxos Made Live"), verified
  cross-links, and a reading guide that foregrounds §2.1 and §4.
- Fact-checked against the paper text: typically five replicas, 12-second default KeepAlive lease
  extension rising toward ~60s under load, 45-second default grace period, one cell per datacentre
  of several thousand machines, and the outage statistics (61 outages over 700 cell-days, most
  under 15s, 52 under 30s).
- Called out where ZooKeeper deliberately diverges from Chubby (wait-free API instead of a lock
  service; reads served from any replica instead of master-only) rather than presenting it as a
  straight clone.

## 2026-04-18
- Scaffolded `Chubby` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
