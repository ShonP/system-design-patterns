# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Read Repair` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added `notebooks/01_stale_replica.ipynb` and `notebooks/02_read_repair.ipynb`.
- QA review: rewrote both notebooks with a clearer bad→best progression (read-one → quorum → blocking repair → async repair → probabilistic repair), added quantitative stale-rate simulation and an LWW/vector-clock discussion.
- Added `notebooks/03_anti_entropy_and_hints.ipynb` covering hinted handoff and a Merkle-tree anti-entropy sweep so the lab shows how read-repair fits with the other Dynamo-style repair mechanisms.

## 2026-08-20
- **Bug fix:** `ReadRepairCoordinator` repaired every replica in the cluster, including ones it
  never contacted. A coordinator cannot know what an un-queried replica holds; repairing it is a
  blind write. Repair is now limited to responders — which is also *why* cold keys never heal.
- **Bug fix:** `stale_rate` picked one replica for the name and a different one for the value.
- The quorum-read demo only ever tested the quorum that excluded the stale replica; all three
  pairs are now exercised.
- Notebook 3's hint coordinator was unbounded while the prose claimed hints expire and are
  dropped. It now has a cap, and the overflow leaves keys explicitly to anti-entropy.
- Added a "when you need this" section, including the case where none of these mechanisms apply
  (consensus-replicated writes).
