# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Segmented Log` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added `01_single_file_log.ipynb` (BAD: single growing file, O(n) deletes).
- Added `02_segmented_log.ipynb` (BETTER: rolling segments, O(1) retention, cross-segment reads, real-world references).
- Added `03_sparse_index_and_recovery.ipynb` (BEST: sparse in-memory index for offset lookup, torn-write crash recovery).

## 2026-08-20
- Added the torn write the length-only frame **silently accepts**: crash debris that parses as a
  plausible record is admitted, and recovery truncates after it. Fixed with a `[len][crc32]`
  frame whose recovery rejects phantom records, torn payloads and single-bit rot.
- Added rollover-boundary invariants (no segment over the cap, no record spanning two segments,
  every segment self-decodes) and retention invariants (a prefix is dropped, never a hole, never
  the tail) plus a note on the log-start-offset a real system must expose.
- Added a restart test proving the active segment is resumed rather than clobbered — and a note
  that this path does *not* check the tail for a torn write, which is what notebook 3 fixes.
- **Bug fix:** the sparse index recorded a duplicate entry for each segment's first record.
- Lookup cost is now measured (records scanned per lookup, bounded by `INDEX_EVERY`) rather than
  timed.
