# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19
- Notebook 2: Added a new section **"The Simplest Fix: Atomic `UPDATE ... WHERE`"**
  with a 50-users-vs-1-seat stress test showing that a single SQL statement
  with a `WHERE` guard solves most single-row race conditions.
- Notebook 5: Added section on **distributed-lock caveats** — GC-pause failure
  mode, fencing tokens, Redlock + clock skew, retry-with-backoff, idempotency
  keys.
- Notebook 5: Fixed cell ordering so the "Reset & Run" cells for the failed-saga
  demo appear **before** the demo itself.
- Notebook 5: Fixed RedisInsight host instruction (use `redis` service name,
  not `host.docker.internal`, since RedisInsight runs inside the compose network).
- README: Fixed `cd` path (`04-patterns/…` instead of `patterns/…`) and clarified
  Jupyter kernel registration step.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
