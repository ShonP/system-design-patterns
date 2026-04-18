# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Quorum (N, R, W)` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
- Added `notebooks/01_quorum_basics.ipynb` with bad→best progression (single
  node → `W=R=1` eventual → `W+R>N` strong) and fixed a demo bug where the
  stale-read example didn't actually produce stale reads.
- Added `notebooks/02_tuning_and_tradeoffs.ipynb` — availability vs quorum
  size (binomial model + matplotlib) and a tail-latency simulation.
- Added `notebooks/03_sloppy_quorum_and_repair.ipynb` — sloppy quorum,
  hinted handoff, read repair, LWW vs vector clocks vs CRDTs.
