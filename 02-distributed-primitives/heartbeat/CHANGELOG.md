# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Heartbeat` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added `notebooks/01_fixed_heartbeat.ipynb` and `notebooks/02_phi_accrual.ipynb`.
- QA pass: fixed bug in `01_fixed_heartbeat.ipynb` where `last_seen=-inf` made the monitor declare the node dead at `t=0` (so `detection_delay` was always `None`).
- Rewrote both notebooks for clarity: real-world systems table (HDFS, K8s, Cassandra, GFS), trade-off plot, "k missed beats" rule, phi-vs-fixed side-by-side comparison under a network blip.
- Added `notebooks/03_real_world.ipynb` covering push vs pull, central vs gossip, and fencing / split-brain.

## 2026-08-20
- **Bug fix:** `simulate_fixed_timeout` never reported a detection delay when the detector
  flipped to DOWN just before the real death, leaving gaps in the trade-off curve.
- **Bug fix:** a plot title claimed a "4s network blip"; the blip is 1.5s.
- Corrected the notebook-2 claim that phi rides out the blip — at default settings it does not.
  The comparison now prints the verdict and points at the phi-accrual lab.
- The false-positive vs detection-delay trade-off is now asserted (both curves monotone and
  opposed, no setting optimal on both axes), as is the push-vs-pull message-count model.
