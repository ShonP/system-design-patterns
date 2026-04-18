# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Write-Ahead Log (WAL)` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added `notebooks/01_what_is_a_wal.ipynb` (bad/better/best progression) and `notebooks/02_crash_and_recovery.ipynb` (SIGKILL child-process crash demo).
- Added torn-write demo cell to notebook 01 (proves replay skips half-written tail lines).
- Added `notebooks/03_checkpoints_and_compaction.ipynb` — checkpoints, atomic snapshot+rename, log truncation, and `snapshot + tail-of-log` recovery.
- Added `notebooks/04_fsync_and_group_commit.ipynb` — benchmarks no-fsync vs fsync-per-write vs group commit, and maps the knob to Postgres / InnoDB / SQLite / Kafka settings.
