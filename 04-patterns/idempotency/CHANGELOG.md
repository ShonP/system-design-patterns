# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20

### Fixed
- `04_concurrent_retries.ipynb` — the "GOOD: atomic INSERT" demo was itself racy and
  double-charged on roughly 1 run in 7 while still printing "exactly ONE charge applied".
  Root cause: a single `sqlite3.Connection` shared across threads (one transaction state,
  so a polling reader could disturb the winner's write transaction, which then rolled back
  and released its own claim). Replaced with a per-thread connection (`threading.local`,
  file-backed WAL database) and `BEGIN IMMEDIATE`, which is also what a real connection
  pool looks like. Added `assert`s so the cell fails loudly instead of printing a ✅.
- `02_idempotency_keys.ipynb` — the different-body rejection was labelled `409`; Stripe
  returns `400` for that case and reserves `409` for a concurrent in-flight request.

### Added
- `01_double_charge.ipynb` — runnable natural-idempotency demo (end-state `PUT` vs delta
  `POST`), plus a table of delta operations and their naturally idempotent rewrites, so
  readers can tell when they need a key at all.
- `02_idempotency_keys.ipynb` — the per-caller scoping bug: two callers picking the same
  key string share a cache entry, so one silently loses their charge and receives the
  other's response. Fixed by making the storage key `(caller, idempotency_key)`.
  Operational notes extended with TTL sizing, storing the response (not a flag), and what
  to cache on `4xx` vs `5xx`.
- `04_concurrent_retries.ipynb` — the wedged-claim failure: a process that dies after
  claiming a key leaves `IN_PROGRESS` forever and no retry can ever progress. Fixed with a
  **lease** (expiring claim) taken over by a conditional `UPDATE`, plus the honest caveat
  that a lease bounds the wedge but does not prove the dead worker's side effect never
  happened. Added "when to use which mechanism", "when you don't need any of this", and
  what the pattern costs.

### Changed
- Hygiene: kernelspec normalized to `Python 3 (.venv)`; saved outputs and execution counts
  stripped from all four notebooks.

## 2026-04-19
- Expanded `01_double_charge.ipynb` with a flaky-network retry simulation and an HTTP-method idempotency primer.
- Expanded `02_idempotency_keys.ipynb` with a request-body fingerprint check that rejects key reuse with a different body (`409 Conflict`).
- Expanded `03_database_dedup.ipynb` with an explicit crash simulation (showing why the idempotency insert and the side effect must share one transaction), a TTL/purge example, and an at-most-once / at-least-once / exactly-once-effect note.
- Added `04_concurrent_retries.ipynb`: demonstrates the check-then-act race under concurrent retries and fixes it with an atomic `INSERT` plus an `IN_PROGRESS` status marker. Includes a real-world implementations table (Stripe, AWS SQS FIFO, Kafka, PayPal, GitHub).

## 2026-04-18
- Scaffolded `Idempotency` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
