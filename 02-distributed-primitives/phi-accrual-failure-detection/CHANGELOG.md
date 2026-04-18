# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Phi Accrual Failure Detection` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added notebook 1 (fixed-timeout problem with visual) and notebook 2 (phi accrual detector).
- Expanded lab content (QA review):
  - Notebook 1: added timeline visualization of DOWN bands for three timeouts, clearer tradeoff framing.
  - Notebook 2: math walkthrough with reference table (φ=1/3/8/12), `warmup` samples to suppress cold-start false alarms, tighter phi clamp (`1e-20`) so phi can reach Akka's threshold, network-blip survival demo vs fixed timeout.
  - Added notebook 3 (`03_real_world_cluster.ipynb`): 5-node cluster with healthy, GC-paused, partitioned, crashed, and slow-but-alive nodes; three layered decision thresholds (route-away / evict / fence); tuning notes on `min_std`.
