# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Gossip Protocol` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added notebook `01_what_is_gossip.ipynb` (central broadcast vs push gossip, S-curve, fanout sweep).
- Expanded notebook 1: message-cost comparison, convergence math (`O(log_{1+f} N)`), message-loss robustness experiment, real-world systems table.
- Added notebook `02_push_pull_and_failure_detection.ipynb`: push vs pull vs push-pull comparison, anti-entropy with `(generation, heartbeat)` versioning, gossip-based failure detection, seed-node bootstrap demo.
