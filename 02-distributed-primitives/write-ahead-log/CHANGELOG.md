# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Write-Ahead Log (WAL)` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added `notebooks/01_what_is_a_wal.ipynb` (bad/better/best progression) and `notebooks/02_crash_and_recovery.ipynb` (SIGKILL child-process crash demo).
- Added torn-write demo cell to notebook 01 (proves replay skips half-written tail lines).
- Added `notebooks/03_checkpoints_and_compaction.ipynb` — checkpoints, atomic snapshot+rename, log truncation, and `snapshot + tail-of-log` recovery.
- Added `notebooks/04_fsync_and_group_commit.ipynb` — benchmarks no-fsync vs fsync-per-write vs group commit, and maps the knob to Postgres / InnoDB / SQLite / Kafka settings.

## 2026-08-20
- **Corrected a false safety claim.** The lab stated newline-delimited JSON is "atomic per line"
  and recovered by *skipping* unparseable lines. Notebook 1 now breaks it on purpose: a torn
  record followed by later appends fuses two records, skip-and-continue drops both, and the
  recovered state has a **hole** in the middle rather than being a prefix of the writes.
- Added the real fix: `[len][crc32][payload]` framing with recovery that **truncates** at the
  first record that fails to verify. Tested against a torn tail, a torn record followed by more
  appends, and a single flipped bit in an intact-length record.
- Notebook 3 now crashes between the checkpoint's rename and truncate steps (safe) and in the
  unsafe order (total loss), so the ordering claim is demonstrated rather than asserted.
- Notebook 4 counts fsyncs and the durability window instead of relying on wall-clock timings.
