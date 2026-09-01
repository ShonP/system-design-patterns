# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-21
- **Notebook 1** — the hot-shard simulator used Python's `hash()`, which is salted
  per process, so the partition assignment moved on every kernel restart. Swapped it
  for `zlib.crc32` (a stand-in for Kafka's murmur2) and seeded the click stream. The
  "BETTER" strategy also over-claimed: with 3 partitions and 10 sub-keys the busiest
  partition still held 54 % of traffic while the prose said "spreads evenly". Widened
  the suffix range to 32 (busiest → 38 %) and added the honest ceiling — you can never
  beat `1/num_partitions` by splitting a key, past that you need more partitions.
  Events are now tagged with a `RUN_ID` so a second run stops silently consuming the
  first run's messages.
- **Notebook 2** — `get_window_start` read a timestamp without an offset as *local*
  time, silently moving clicks hours out of their window; it now treats naive
  timestamps as UTC. Added boundary assertions proving windows are half-open
  `[start, end)` so an event landing exactly on a boundary lands in exactly one window.
- **Notebook 2** — the "late-arriving events" section listed **Watermark** as a strategy
  and never implemented one; nothing was ever actually dropped. Added a real
  `WatermarkAggregator` (`watermark = max event time − allowed lateness`, window closed
  when `window_end <= watermark`) driven by a scripted out-of-order arrival sequence:
  one click is late-but-merged, two are dropped, and re-running with a wider grace
  period recovers all of them.
- **Notebook 2** — new **Step 6, "At-Least-Once Delivery Double-Counts"**. The additive
  UPSERT was never safe to apply twice, which is the one defect in an ad system that
  ends in a refund. The section reproduces the double-count (a replayed batch bills 20
  clicks for 10), then fixes it with an idempotency key: a deterministic batch id
  written to `applied_batches` in the same transaction as the counts.
- **Notebook 2** — the sliding-window SQL used `ROWS BETWEEN 4 PRECEDING`, which counts
  *rows*, not minutes. A minute with zero clicks writes no row, so on a gappy series it
  reaches back six minutes and reports a 5-minute total that is too big. Switched to
  `RANGE BETWEEN INTERVAL '4 minutes' PRECEDING`, and the notebook now deletes one
  aggregate row on purpose to make the two frames disagree in front of the reader.
- **Notebook 2** — the reconciliation job compared truth to streaming with a `LEFT JOIN`
  from the raw events, so a **phantom** aggregate row (a window with no raw events
  behind it — exactly what a double-count leaves) was invisible and survived the
  "repair". Now a `FULL OUTER JOIN` plus a `DELETE` for orphans, with both an
  under-count and a phantom injected and the job re-run to prove zero mismatches remain.
  Also dropped a stray `AT TIME ZONE 'UTC'` that converted an already-UTC `TIMESTAMP`
  through `timestamptz` and would shift every window on a non-UTC server.
- **Notebook 3** — the IP rate limiter was labelled a "sliding window" but is an
  `INCR`/`EXPIRE` **fixed** window. Relabelled it and added a demo that reproduces the
  classic 2x boundary burst (10 clicks in 2 seconds all allowed against a limit of 5)
  next to a sliding-window log that holds the line at 5.
- **Notebook 3** — the Redis memory prose claimed "≈ 3.6 GB" while the notebook's own
  budget cell computed ~10 GB; reconciled the two by separating raw key bytes from
  per-key overhead, and flagged the 64-byte overhead figure as a rule of thumb.
- **All three notebooks** — seeded the RNGs, tagged produced events with a per-run id so
  re-running a notebook no longer aggregates a previous run's Kafka backlog, and added
  assertions throughout so each lab fails loudly if it stops reproducing its own lesson
  (planned-vs-actual window counts, watermark verdicts, replay absorption, ROWS-vs-RANGE
  divergence, reconciliation convergence, dedup/HMAC rejection counts, end-to-end
  click conservation).
- **README** — added a "What This Lab Deliberately Does *Not* Do" section covering the
  gaps between the toy and the real system.

## 2026-04-19
- Swapped the broken `bitnami/kafka:3.7` image (removed from Docker Hub) for
  the maintained `confluentinc/cp-kafka:7.6.0` image. All listener names
  and external port (`9094`) are preserved so notebooks run unchanged.
- **Notebook 1** — added a new "Hot Shard Mitigation" section that simulates
  a viral ad (80 % of traffic on one `ad_id`) and shows how appending a
  random suffix to the partition key rebalances the load.
- **Notebook 2** — added a "Sliding Windows" section (SQL window-function
  and pure-Python implementations) so the notebook finally delivers on its
  title, plus a "Reconciliation & Lambda Architecture" section that injects
  a streaming drift and repairs it from the raw events table.
- Verified every notebook executes cleanly end-to-end via
  `jupyter nbconvert --execute`.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
