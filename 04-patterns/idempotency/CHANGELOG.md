# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19
- Expanded `01_double_charge.ipynb` with a flaky-network retry simulation and an HTTP-method idempotency primer.
- Expanded `02_idempotency_keys.ipynb` with a request-body fingerprint check that rejects key reuse with a different body (`409 Conflict`).
- Expanded `03_database_dedup.ipynb` with an explicit crash simulation (showing why the idempotency insert and the side effect must share one transaction), a TTL/purge example, and an at-most-once / at-least-once / exactly-once-effect note.
- Added `04_concurrent_retries.ipynb`: demonstrates the check-then-act race under concurrent retries and fixes it with an atomic `INSERT` plus an `IN_PROGRESS` status marker. Includes a real-world implementations table (Stripe, AWS SQS FIFO, Kafka, PayPal, GitHub).

## 2026-04-18
- Scaffolded `Idempotency` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
