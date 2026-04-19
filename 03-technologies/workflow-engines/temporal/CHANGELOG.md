# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19
- Fixed outdated `enterprise-patterns/long-running-jobs-temporal` paths in the README and notebooks 2–4 so they match the current `03-technologies/workflow-engines/temporal` location.
- Fixed the idempotency demo in notebook 2 to catch `WorkflowAlreadyStartedError` (the exception raised by modern `temporalio`) instead of the lower-level `RPCError`.
- Added notebook **`05_queries_heartbeats_testing.ipynb`** covering four production-critical concepts that were missing: **Queries** (reading live workflow state), **Heartbeats** (keeping long activities alive and resumable), **Continue-As-New** (running workflows forever without history bloat), and **Testing** with `WorkflowEnvironment.start_time_skipping()` (unit-test workflows in CI without Docker).

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
