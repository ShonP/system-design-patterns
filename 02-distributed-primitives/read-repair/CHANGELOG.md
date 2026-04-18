# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Read Repair` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added `notebooks/01_stale_replica.ipynb` and `notebooks/02_read_repair.ipynb`.
- QA review: rewrote both notebooks with a clearer bad→best progression (read-one → quorum → blocking repair → async repair → probabilistic repair), added quantitative stale-rate simulation and an LWW/vector-clock discussion.
- Added `notebooks/03_anti_entropy_and_hints.ipynb` covering hinted handoff and a Merkle-tree anti-entropy sweep so the lab shows how read-repair fits with the other Dynamo-style repair mechanisms.
