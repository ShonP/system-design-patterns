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

## 2026-08-20
- The `W + R > N` rule is now **proved** rather than sampled: an exhaustive enumeration of every
  write-set/read-set pair for `N=5` confirms zero disjoint pairs exactly when the inequality
  holds.
- Added the missing near-miss failure: `W=R=2` on `N=5` now produces an actual stale read from a
  disjoint read set, with the same cluster returning fresh data at `W=4`.
- **Bug fix:** `Cluster.read` always contacted the first R replicas in list order, so the
  "quorum" was never varied; it now samples R live replicas from a seeded RNG, and `write_to`
  lets a demo pin the write set.
- Notebook 3 now runs a **strict quorum failing** before introducing sloppy quorum, so the
  availability cost is demonstrated rather than asserted.
- **Bug fix:** `quorum_read_with_repair` read from whichever nodes sorted first rather than the
  key's preferred replicas.
