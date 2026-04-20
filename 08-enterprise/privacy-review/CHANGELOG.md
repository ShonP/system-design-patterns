# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Fixed `psycopg2` cursor calls in notebooks 2–4: `conn.cursor(psycopg2.extras.RealDictCursor)` is invalid (treats the class as a cursor name); replaced with the correct keyword argument `cursor_factory=psycopg2.extras.RealDictCursor` so notebooks 2, 3, and 4 now execute without errors.
- Added `ON DELETE` behaviour to foreign keys in `db/init.sql` so the retention engine can hard-delete users without foreign-key violations:
  - `payment_methods.user_id` → `ON DELETE CASCADE` (card data must die with the account; matches the "immediate deletion" retention policy).
  - `orders.user_id`, `support_tickets.user_id`, `activity_log.user_id` → `ON DELETE SET NULL` (keep the row for its own retention window, but unlink the erased user).
- Notebook 4: `purge_hard_delete()` now accepts an optional `extra_where` SQL filter and logs it in the audit trail; both the tutorial loop and `RetentionEngine` use it so `users` is only erased when `account_status = 'deleted'` (GDPR 30-day grace period). The retention scanner applies the same filter so reported "expired" counts match the rows that will actually be purged.
- Verified end-to-end: `uv run jupyter nbconvert --execute` succeeds on all four notebooks against a freshly recreated PostgreSQL + Redis stack.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
