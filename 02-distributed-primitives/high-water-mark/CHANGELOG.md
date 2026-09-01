# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18

- Scaffolded `High-Water Mark` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added notebooks `01_no_high_water_mark.ipynb` and `02_with_high_water_mark.ipynb`.
- **Improved notebook 01**: added beginner-friendly bank/branches analogy, clearer `naive_replicate` walkthrough, real-world MongoDB `w:1` parallel.
- **Improved notebook 02**: introduced quorum reasoning, `match_index` per follower, plus a matplotlib chart showing the gap between the leader's local tail and the HWM.
- **Added notebook 03** `03_heartbeats_and_truncation.ipynb`: message-passing model, HWM propagation via heartbeats / piggybacked `AppendEntries`, follower truncation after a leadership change, and a comparison table for Kafka, Raft, MongoDB, PostgreSQL, and ZooKeeper.
- Verified all three notebooks execute end-to-end with `jupyter nbconvert --execute`.

## 2026-08-20
- **Bug fix:** `Follower.receive_append` truncated the log suffix on *every* re-sent entry, not
  only on a conflict — re-sending an entry a follower already had destroyed everything after it.
  Truncation is now conflict-only, with a regression assertion.
- The notebook-3 truncation demo was passing only because of that bug; it now models what Kafka
  actually does (an explicit `truncate_to` before the rejoining node resumes fetching).
- **Bug fix:** `Leader.high_water_mark` raised `IndexError` before `quorum` nodes had reported.
- Corrected the claim that a follower learns the new HWM from the same `AppendEntries` that
  carried the entry — it cannot; the HWM always lags by one round trip.
- Added a client-facing `read()` that *refuses* offsets above the HWM (invisibility is now
  enforced, not just unlisted) and an exhaustive check that no reachable failover rolls the
  high-water mark backwards.
