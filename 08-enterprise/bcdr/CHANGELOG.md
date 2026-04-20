# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

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
