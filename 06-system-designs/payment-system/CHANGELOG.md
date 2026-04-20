# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Fixed `db/init.sql` seed: `pi_010` reused `pi_001`'s idempotency key, which violated the
  `UNIQUE (merchant_id, idempotency_key)` constraint and caused Postgres init to fail entirely.
- Fixed FK violation in Notebook 3 (section on unbalanced ledgers): the orphan-debit demo
  now creates a real `payment_intent` + `transaction` first so `ledger_entries.transaction_id`
  satisfies the FK. Cleanup deletes all three rows in the correct order.
- Fixed FK violation in Notebook 4: `run_fraud_checks` demos now pre-create the referenced
  `transactions` rows via a new `ensure_test_txn` helper so `fraud_signals.transaction_id`
  satisfies the FK.
- Added a "Bad Practice First: Single-Entry Bookkeeping" section to Notebook 3 establishing
  a bad-to-best progression before introducing double-entry.
- Added a "Refunds: Reversing the Ledger" section to Notebook 3 demonstrating append-only
  refunds as reversing debit/credit pairs, plus a verification query showing net-zero per
  account after refund.
- Added a "Closing the Loop: Reconciliation for Timeouts" section to Notebook 1 that resolves
  transactions left in `timeout`/`pending` by querying the (simulated) card network.
- All four notebooks verified to execute end-to-end via `jupyter nbconvert --execute`.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
