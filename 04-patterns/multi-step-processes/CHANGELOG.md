# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (repo-wide verification pass)
- **Fix**: the stack could not start. `temporalio/admin-tools:1.24` does not exist on Docker Hub (*"failed to resolve reference ... not found"*); pinned both Temporal images to 1.26.2 so they stay in lockstep.
- **Fix**: `DB=postgresql` is not a valid driver for the auto-setup image and made the server exit(1). Corrected to `postgres12`.
- Lab re-verified end-to-end against the stack.

## 2026-04-19
- Fixed `workflow.RetryPolicy` → `RetryPolicy` from `temporalio.common` in notebooks 04 and 05 (the old name doesn't exist in the SDK and would crash the workflow).
- Expanded README services table to include Redis, Adminer, and RedisInsight, and added a "Notebook Dependencies" table so learners know which infra each notebook needs.
- Named the **Saga pattern** explicitly in notebook 02 so readers learn the canonical term for "sequence of steps + compensating undo actions".

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
