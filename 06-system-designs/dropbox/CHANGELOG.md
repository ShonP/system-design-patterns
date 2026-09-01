# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.

## 2026-04-20
- Fixed incorrect "Next notebook" cross-references in notebooks 1, 2, 3 summaries (they had been written in the wrong order after the series was reordered).
- Fixed final summary table in notebook 4 that mislabelled notebooks 2 and 3.
- Corrected `cd 06-system-designs/dropbox` → `cd 06-system-designs/dropbox` in README and all notebook setup cells.
- Added missing `requests` dependency to `pyproject.toml` (used by notebooks 1 and 4 for presigned URL HTTP PUT/GET).
- Verified every notebook executes top-to-bottom against the docker-compose stack with no errors.

## 2026-08-21 (correctness audit)
- **NB3 — the CDC demo did not demonstrate CDC.** The comparison ran on
  `bytes(range(256)) * 256`, which is perfectly periodic: all eight fixed-size chunks were
  byte-identical, and the rolling hash never once satisfied `(h & mask) == 0`, so every CDC
  boundary came from the `max_size` cap. The notebook printed `Fixed-size: 0.0% dedup` /
  `CDC: 0.0% dedup` and fell through to the hedge branch — the lab's headline lesson was
  asserted in prose and refuted by its own output. Replaced with 256 KB of seeded
  pseudo-random bytes: fixed-size now reuses **0%** after a 110-byte insert at position 100,
  CDC reuses **97.9%** and re-cuts exactly one chunk. Added assertions on all four.
- **NB3 — the dedup ratio was overstated (69.6% vs the true 44.9%).** "Physical bytes"
  summed unique *chunk* rows only, so the 40 KB object written by the file-level dedup demo
  (which has no chunk rows) counted as free. The already-computed `physical_file_level`
  was never used. Physical is now chunk bytes + whole-object bytes, and the cell
  cross-checks the total against the byte count MinIO actually reports.
- NB3: documented what the rolling hash really is (a 32-bit shift-and-add over an effective
  32-byte window, not a Rabin polynomial) and why resetting it at each boundary is safe only
  while `min_size > 32`; both are now asserted inside `cdc_chunks`.
- **NB2 — the change feed was scoped by the wrong column.** `poll_changes` filtered on
  `sync_events.user_id`, the user who *caused* the change, so a collaborator never saw
  edits to a file shared with them. "Step 6: both devices poll" did not poll: it ran one
  global query. Scoped the feed by access (owner OR shared_with) and made Step 6 actually
  call `poll_changes` once per device.
- **NB2 — "keep both" preserved Bob's edit somewhere Bob could not reach.**
  `resolve_keep_both` ignored its `editor_id` argument and filed the copy under the owner
  with no share row, so the losing editor got no record of it. It now shares the copy back
  when the editor is not the owner, and the cell asserts the copy appears in Bob's feed.
- NB2: the keep-both demo re-used the same content last-write-wins had just written, so it
  "rescued" a copy identical to the live file. It now parks the laptop edit that LWW
  destroyed, which is the point of the strategy.
- NB2: removed the `time.sleep(0.5)` guesses around Redis pub/sub. Subscribers now signal a
  `ready` event on the SUBSCRIBE acknowledgement, publishers wait on the result with a
  deadline, and `SyncClient._poll_loop` waits one interval before its first poll so the
  poll path can no longer race pub/sub for the same event.
- NB1: `~67 minutes` for 50 GB on 100 Mbps contradicted the notebook's own printed `71.6`
  (decimal GB in the prose, binary GB in the code). The figure is now derived from the loop.
- NB1: the "partially failed upload" only *narrated* the failure — chunks 3 and 4 were
  simply never sent. They are now PUT with a corrupted signature, so MinIO really rejects
  them and they really stay `pending`; the resume then asserts it re-sends exactly those.
- NB4: the presigned-URL lesson was undermined by `docker-compose.yml`, which ran
  `mc anonymous set download` — the bucket was world-readable, so the "private object"
  premise was false. Changed to `mc anonymous set none`, and notebook 4 now proves it with
  an unsigned GET before generating any signature.
- NB4: the cache-vs-database benchmark called `print()` 150 times inside the timed region.
  Added `verbose=` to `get_shared_with_me`, switched to `perf_counter`, reported p50
  alongside the mean, and stated the caveat that both stores are on localhost.
- NB4: `share_file` accepted an `owner_id` it never checked, so any recipient could
  re-share a file they did not own. It now rejects non-owners, with a demo.
- NB4: `last_seen` was only bound inside the `if events:` branch and read unconditionally
  afterwards (NameError on an empty feed). Initialised to 0.
- Added assertions throughout so each notebook fails loudly if it stops reproducing its own
  lesson: chunk round-trip and index density (NB1), resumable-upload targeting, reassembly
  fingerprint; conflict actually firing and both edits surviving (NB2); file-level dedup
  leaving one object, chunk reuse counts, refcount deleting only unshared chunks (NB3);
  the full permission matrix, the revoke-vs-signed-URL gap, and cache/DB agreement (NB4).
- Seeded every RNG (`random.Random(...)` instead of `os.urandom`) so the printed numbers
  are reproducible.
- README: added a "What This Lab Does *Not* Do" table (rolling hash vs Rabin, pub/sub vs
  durable cursors, whole-file re-upload vs block-level delta sync, sync refcount vs async GC).
