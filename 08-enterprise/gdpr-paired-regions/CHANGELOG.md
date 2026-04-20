# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- **Notebook 1**: Added a "Bad → Best: Why Geo-Routing Matters" section with a
  runnable anti-pattern (`create_user_BAD`) that ignores `country_code`,
  contrasted against the proper geo-routed `create_user_in_correct_region()`.
  Mentions the Schrems II ruling.
- **Notebook 3**: Added a "Bad → Best: Naive DELETE Leaves Orphans" demo that
  proves a one-line `DELETE FROM users` leaks PII through child tables that
  lack `ON DELETE CASCADE`.
- **Notebook 3**: Added a new section on the **Right to Access (Article 15)**
  with a runnable `export_user_data()` DSAR helper that returns all PII as
  machine-readable JSON.
- **Notebook 4**: Added a new section on the **72-hour breach notification
  rule (Article 33)** with a runnable `check_breach_sla()` countdown helper.
- All four notebooks re-executed end-to-end against the docker-compose stack.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
