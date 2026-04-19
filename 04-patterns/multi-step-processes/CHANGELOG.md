# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19
- Fixed `workflow.RetryPolicy` → `RetryPolicy` from `temporalio.common` in notebooks 04 and 05 (the old name doesn't exist in the SDK and would crash the workflow).
- Expanded README services table to include Redis, Adminer, and RedisInsight, and added a "Notebook Dependencies" table so learners know which infra each notebook needs.
- Named the **Saga pattern** explicitly in notebook 02 so readers learn the canonical term for "sequence of steps + compensating undo actions".

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
