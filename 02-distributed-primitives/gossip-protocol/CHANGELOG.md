# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Gossip Protocol` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added notebook `01_what_is_gossip.ipynb` (central broadcast vs push gossip, S-curve, fanout sweep).
- Expanded notebook 1: message-cost comparison, convergence math (`O(log_{1+f} N)`), message-loss robustness experiment, real-world systems table.
- Added notebook `02_push_pull_and_failure_detection.ipynb`: push vs pull vs push-pull comparison, anti-entropy with `(generation, heartbeat)` versioning, gossip-based failure detection, seed-node bootstrap demo.

## 2026-08-20
- **Bug fix (significant):** `merge()` returned the peer's live `NodeState` object, so every
  node's table ended up aliasing one shared mutable record per peer. `tick()` then bumped a
  counter every table already pointed at, information "teleported" across the cluster, and the
  heartbeat-propagation plot was measuring nothing. `NodeState` is now `frozen=True`.
- Added a regression check that gossip actually takes rounds to spread (peers hold stale views),
  which is the observable the aliasing bug destroyed.
- Convergence vs fanout and vs cluster size are now averaged over seeds and asserted; loss
  robustness, the crash detector's no-false-positive property, and the seed-node partition are
  asserted rather than eyeballed.
