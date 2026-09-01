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

## 2026-08-20
- **Corrected a false claim.** Notebook 2 asserted in prose, a chart title and the recap that phi
  "never crosses 8" during the 1.5s blip, while its own output printed a peak of 13.41 — a
  Cassandra-default detector evicts a healthy node there. The notebook now asserts the false
  positive, explains why phi is right and the threshold is wrong (a 2.5s silence is a 6-sigma
  event under the learned distribution), and tunes `min_std` to fix it without losing crash
  detection.
- Replaced the overstated "killer feature" with the advantage that actually holds: phi adapts to
  a node with a *different cadence*, which a fixed timeout cannot. Demonstrated and asserted.
- Verified the formula against `-log10(P(interval > Δ))` computed independently from
  `statistics.NormalDist`, at z = 0, 1, 2, 3, 4, 6, plus the two landmark values.
- Added a check that phi genuinely *accrues* (strictly increasing, four thresholds firing at four
  different times) rather than being a rebadged timeout, and documented the phi=20 clamp.
- Notebook 3's per-node escalation table is now asserted node by node.
