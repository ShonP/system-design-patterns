# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (repo-wide verification pass)
- **Fix**: notebooks 3 and 4 could not run after notebook 2. Notebook 2 ends by fencing the primary -- it kills the container on purpose, which is the STONITH step of a real failover -- and nothing brought it back, so the next notebooks died on *"connection to server at localhost, port 5432 failed: Connection refused"*. Both now start with a preflight that restarts the primary, framed as the rebuild-the-fenced-node step that always follows a production failover.
- All 4 notebooks now execute end-to-end **in order** from a cold `docker compose up`.

## 2026-04-20
- Fixed `db/standby-entrypoint.sh` to run `pg_basebackup` and `postgres` as
  the `postgres` OS user via `gosu` (the server refuses to run as root on
  current `postgres:16` images).
- Switched notebook kernel metadata to the standard `python3` kernel so the
  repo's `.venv`-per-lab convention works without a separate `ipykernel
  install` step. Updated README accordingly.
- Added to Notebook 3 (Backup Strategies):
  - The **3-2-1 backup rule** (and the modern 3-2-1-1-0 variant).
  - A runnable **"Replication is NOT a Backup"** demo: takes a backup,
    deletes every order on the primary, shows the delete replicates to the
    standby instantly, then restores from the backup.
- Added a **Famous Outages** section to the README with the BCDR lesson from
  each (GitLab 2017, Maersk NotPetya, British Airways 2017, Delta 2016,
  Facebook 2021, Salesforce 2019, Rogers 2022) mapped to the notebooks.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.

## 2026-08-21 (correctness audit)

The 2026-08-20 fix got notebooks 3 and 4 to *start* again, but it was not a
coherent repair: it restarted the fenced primary and left the promoted standby
running as a second, independent primary. That is split-brain, produced by the
repair itself, and it silently discarded the write notebook 2 makes on the new
primary. Everything downstream then lied.

### Fixed — the failback (the defect that mattered)

- **Notebook 3 cell 1 / Notebook 4 cell 1**: replaced the "restart pg-primary"
  preflight with a real `failback()`. It captures the rows written on the
  promoted node during the failover window, un-fences the old primary, replays
  those rows onto it, re-clones the standby so streaming replication resumes,
  and then *verifies* all of it (primary writable, standby in recovery and
  streaming, carried-back rows visible on both). It is a no-op when the
  topology is already correct, so a cold start is unaffected.
- **Notebook 3 cell 14** (`Replication is NOT a Backup`): with two primaries the
  `DELETE` on 5432 never reached 55433, yet the cell printed *"The standby was
  NOT a safety net — the DELETE replicated instantly"* unconditionally. The
  claim is now derived from the data, guarded by `assert` on `pg_is_in_recovery()`
  before the demo starts, and the delete is polled for rather than slept on.
- **Notebook 3 cell 14**: the restore was `pg_restore --data-only` over *every*
  table, which re-inserts live `audit_log` rows and fails on the primary key
  once anything else has written there. Scoped it to the three tables the demo
  actually deletes, and asserted the recovery replicated back out to the standby.
- **Notebook 4 Phase 1/4**: with no replication, `pg_ctl promote` failed on an
  already-promoted node while `pg_is_in_recovery()` returned false, so the drill
  reported *"✅ Standby promoted"* for a promotion that never happened. Phase 1
  now aborts hard when nothing is streaming; Phase 4 asserts on the poll result.

### Fixed — RPO and RTO arithmetic

- **Notebook 4** conflated the two numbers: it printed a *record count* under
  the heading "Data Loss (RPO)". RPO is a time. Phase 2 now records the wall
  clock of every acknowledged commit, Phase 3 computes the RPO as the gap
  between the last acknowledged commit and the last one present on the standby,
  and Phase 5 grades RPO and RTO separately against objectives declared in
  Phase 1 *before* the result is known.
- **Notebook 4** could not demonstrate RPO > 0 at all — every last-moment write
  always replicated, so the "records lost" branch was dead code. Phase 2 now
  cuts the replication stream (terminating the walsender; the standby's 5s
  `wal_retrieve_retry_interval` holds it off) and writes three more rows that
  the standby genuinely never sees. The drill now shows what asynchronous
  replication actually costs, and asserts it.
- **Notebook 4 Phase 4/5**: "Total RTO" silently included however long the
  reader spent between cells. Split into a mechanical failover time (graded)
  and a wall-clock figure (reported, explained). Detection time is labelled as
  a floor, not a measurement.
- **Notebook 2 cell 11**: `pre_lsn` was recorded and never used — the "VERIFY
  the standby caught up" step of the documented procedure did not exist in the
  code. It now compares the primary's final WAL position against the standby's
  replay position and asserts the fence was lossless. Code step numbering now
  matches the markdown procedure, which gained the missing **Step 6: failback**.
- **Notebook 1 cell 4**: prose claimed a daily backup "could mean losing
  hundreds of orders" while the notebook's own table printed **16**. At the
  lab's write rate a 5-minute RPO and a 0-second RPO both rounded to zero, so
  the ladder could not show the thing it exists to show. The table now prints
  fractional expected orders *and* the same ladder at a production write rate,
  and the closing line is computed rather than asserted by hand.
- **Notebook 1 cell 6**: the TOTAL column included a reputation cost that had no
  column, so the row did not add up. Added the column, documented the one-hour
  minimum on staff cost, and asserted the columns sum to TOTAL.

### Fixed — backups verified rather than assumed

- **Notebook 3 cell 5**: `pg_restore --list` output was counted whole, so the
  ~10-line `;`-commented header was reported as "objects" and printed as the
  "first 10 objects in backup". Header lines are now filtered, and the five
  seeded tables are asserted present in the listing.
- **Notebook 3 cell 9**: verification compared row counts only — a restore with
  the right number of wrong rows passed. Added a per-table content hash
  (`md5(string_agg(row::text))`) alongside the counts and made a mismatch fail
  loudly. Softened the "this is your backup-based RTO" claim to what it is: one
  component of it.
- **Notebook 3 cell 7**: `pg_basebackup` refuses a non-empty target, so the cell
  could not be re-run. Clears the directory first and asserts both `base.tar.gz`
  and `pg_wal.tar.gz` exist.

### Fixed — determinism and latent bugs

- **Notebook 4 Phase 4** set `conn.autocommit = True` *after* a query had already
  opened a transaction. psycopg2 will not change session state mid-transaction.
  Moved to immediately after `connect()`.
- Replaced every fixed `time.sleep()` used as a synchronisation primitive with a
  bounded poll (notebook 1 cell 11, notebook 2 cells 7 and 11, notebook 3 cell
  14, notebook 4 phases 2/4 and the Redis check). The `sleep(3)` after
  `pg_ctl promote` was being reported as part of the measured RTO.

### Added

- **Notebook 4 Phase 6 — FAILBACK**, with markdown. The drill now ends with the
  cluster back in a runnable, replicated state, and asserts that the write made
  on the promoted node during the outage survived. It also shows the commits
  recovered from the fenced node's disk and states plainly that recovering them
  afterwards does **not** lower the drill's RPO — production `pg_rewind` would
  discard them as diverged history.
- Assertions throughout, so each notebook fails loudly if it stops reproducing
  its own lesson: replication lag bounded (nb1), standby rejects writes and the
  fence is lossless (nb2), backup listing/hashes and the delete-replicates
  demonstration (nb3), exactly the orphaned writes lost, untouched tables
  unchanged across the failover, and topology restored (nb4).
- README: a section on the state notebook 2 deliberately leaves behind and how
  the failback repairs it, plus an honest **"What this lab does NOT do"** table
  (no automatic failover, no quorum, no off-site copy, async-only replication,
  row-level failback instead of `pg_rewind`).

### Addendum — same day, after the lab could actually be executed

The lab had been port-blocked for the whole verification pass (its standby
published host 5433, which a live `crawler_db` on this machine holds), so
everything above was reasoned from reading. Once the standby was moved to
**55433** and the notebooks ran for real, three more defects appeared that no
amount of reading would have found.

- **Notebook 2 cell 11 / Notebook 4 Phase 4 — promotion never worked.**
  `docker exec` runs as root and `pg_ctl` refuses to run as root ("cannot be
  run as root"), so `pg_ctl promote` failed every time. My assertion caught it
  instead of the old code's silent "✅ Standby promoted", but it stranded the
  reader with **no primary at all**. `docker_exec()` now takes a `user`
  argument and the promotion passes `user="postgres"`; the docstring explains
  which PostgreSQL binaries care and why.
- **Notebook 4 Phase 2 — the RPO demonstration was a coin flip.** Terminating
  the walsender and racing the standby's 5 s `wal_retrieve_retry_interval` lost
  the race often enough that the drill reported RPO 0 — teaching the opposite
  of its lesson. (`docker pause` is no better: the WAL sits in the frozen
  standby's socket receive buffer and is read the moment it resumes.) Phase 2
  now **stops the standby container** for the window in which the orphan writes
  are made, and asserts both that the port is closed and that
  `pg_stat_replication` is empty before writing them. A stopped PostgreSQL
  receives nothing and buffers nothing, so the loss is deterministic: across
  cold runs it is always exactly the three orphan writes, RPO ≈ 260–290 ms.
  The `raced_cleanly` escape hatch is gone — the assertion is unconditional.
- **WAL archiving was 100% broken while notebook 3 claimed PITR capability.**
  `pg_stat_archiver` showed `archived_count: 0, failed_count: 20` and the cell
  printed *"WAL archiving + pg_basebackup = point-in-time recovery
  capability"* directly underneath. Cause: Docker creates a named volume's
  mount point owned by root, and the archiver runs as `postgres`, so every
  `cp` failed. Added a `pg-archive-init` service that chowns the archive
  volume before the primary starts, and made `archive_command` idempotent
  (`test -f dest || cp`) so a crash-restarted primary does not stall forever
  re-archiving a segment that is already there. Notebook 3 cell 11 now forces
  a WAL switch and **asserts** `archived_count > 0`, `failed_count == 0` and
  that the files are really on disk — it reports 10 archived / 0 failed / 11
  files. Cell 10's markdown gained the point this defect illustrates:
  `archive_mode = on` says the archiver is running, not that it is working.

Also corrected while running:
- Notebook 3 cell 14 started its replication clock *after* the `DELETE` had
  already been issued and counted, so it reported "0 ms later". The clock now
  starts before the statement; it reports ~67 ms, which is the number that
  means something.
- Notebook 4 Phase 3 prints `pg_last_wal_receive_lsn()` lower than
  `pg_last_wal_replay_lsn()` after the standby restart, which looks like a bug
  and is not. Added a note explaining that the receiver has not started a new
  stream because there is no primary left, and that the replay position is the
  recovery point.
- `failback()` gained a **reattach** path. When nothing was ever promoted —
  the genuinely headless state a half-finished failover leaves behind — the
  standby can rejoin the restarted primary on its own, so wiping its volume
  would be a second outage. It now only re-clones a node that was *promoted*
  and is therefore on a different WAL timeline.
- `pg_query()` documented as read-only: it closes without committing, so
  psycopg2 rolls back. (Found by writing a test that used it for an INSERT.)

Verified by execution, not by reading: `python tools/run_labs.py
08-enterprise/bcdr` passes 4/4 twice in a row from a cold stack
(`docker compose down -v` between runs). All three `failback()` paths were
exercised directly — promoted-node divergence (carries the row back, re-clones,
verifies on both nodes), headless (reattaches in ~6 s, no re-clone, no data
loss), and whole-stack-down (reattaches in ~8 s).
