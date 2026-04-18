# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18 (QA pass)
- Rewrote `01_build_a_merkle_tree.ipynb`: added domain separation (`0x00`/`0x01` prefixes), canonical leaf ordering, canonical serialization notes, ASCII tree visualization, and a "sharp edges / further reading" sidebar on second-preimage attacks.
- Added `02_inclusion_proofs.ipynb`: Merkle proof generation & verification with side bits; bad/ok/best progression; matplotlib plot of proof size vs dataset size; tamper test.
- Renamed notebook 2 → `03_replica_diff.ipynb`: fixed padded-leaf phantom-index bug (filter `idx >= n_real_leaves`); switched `N` to 1000 (non-power-of-two) to exercise padding; corrected bytes accounting (both peers exchange hashes); added matplotlib traffic comparison and a real-world mapping table.
- Updated README with notebook summaries and a real-world Merkle usage table.

## 2026-04-18
- Scaffolded `Merkle Trees` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
