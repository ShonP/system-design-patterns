# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Segmented Log` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added `01_single_file_log.ipynb` (BAD: single growing file, O(n) deletes).
- Added `02_segmented_log.ipynb` (BETTER: rolling segments, O(1) retention, cross-segment reads, real-world references).
- Added `03_sparse_index_and_recovery.ipynb` (BEST: sparse in-memory index for offset lookup, torn-write crash recovery).
