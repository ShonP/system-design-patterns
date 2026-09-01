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

## 2026-08-21 (correctness audit)

Content audit of all four notebooks. Everything below was found by reading the
code against its own prose — the lab executed cleanly the whole time.

### Notebook 1 — Data Classification
- **`classify_column_by_name` matched substrings in both directions**, so `id` matched `tax_id` and every primary key in the database was classified RESTRICTED / government_id, while `description`, `shipped_at` and `shipping_city` matched the `ip` pattern and came back CONFIDENTIAL / network. Replaced with whole-token matching (most severe level wins; inside a level the longest pattern wins, so `ip_address` is `network`, not `address`). Added regression assertions for `id`, `shipped_at` and `ip_address`.
- **Taxonomy conflict**: the scanner filed `date_of_birth` as CONFIDENTIAL while `db/init.sql` filed it as RESTRICTED. Unified on RESTRICTED (DOB + ZIP + sex re-identifies most of the US population) and said so in the README's classification table.
- **The scan reported "✅ No PII patterns detected" for tickets that plainly contain PII** — a full home address, a date of birth, partial card numbers. Reworded to "nothing matched our patterns", and added a ground-truth recall harness: five human-labelled ticket bodies, measured recall (4 of 13 items, 31%), and assertions that pin the lesson — recall must stay below 100%, at least one ticket must scan clean while carrying PII, and the well-formed email/SSN must keep being caught.
- **Content scanning only ran on columns the name scanner had already given up on** (`if level == "public"`), so a column named `email` could never be found to contain SSNs. Now every text column is sampled; classification is upgraded, never downgraded.
- **The registry save was a blind `ON CONFLICT DO UPDATE`** that overwrote human classifications with scanner output — `payment_methods.card_last_four` (CONFIDENTIAL, by the privacy team) would have been silently dropped to `public`. The merge now inserts and upgrades only, reports refused downgrades, and returns real write counts instead of attempted ones.
- Redis is now populated from the registry rather than from the raw scan, since the access-control helper reads the cache; added an assertion that the two agree.
- Added assertions for the access-control demo (unclassified → RESTRICTED, support agent sees email but not SSN, data engineer sees neither) and a note that `[MASKED]` is applied in the SELECT list — the value is still in the table, the backups and the WAL.

### Notebook 2 — Privacy Impact Assessment
- **Averaging six dimensions let a Critical dimension hide behind five quiet ones.** "AI Credit Scoring" scores 5/5 on data sensitivity and 5/5 on automated decisions, averages to 3.83, and was reported as *high* — while the README's own risk table calls that exact feature a 5 / Critical. Added an escalation floor modelled on GDPR Art. 35 (any dimension at 5 → at least medium; a 5 on data sensitivity or automated decisions → at least high; both → critical), which mitigations cannot undercut.
- **Mitigation arithmetic did not match the report.** The report printed "Reduces risk by: 0.5" while the code divided the total by the number of dimensions, applying 0.083. Mitigation credit now reduces the overall score directly and is capped at 0.5 total, with claimed-vs-applied shown in the report.
- **`risk_score` is an `INTEGER CHECK (1..5)` column and the code passed it 2.33**, which PostgreSQL silently rounded — so the dashboard disagreed with the report. It now stores the 1–5 band that matches the assigned level, with an assertion that the stored number means the same thing as the printed one.
- **`approve_pia(1)` / `reject_pia(4)` hardcoded row ids**, which stop being right the moment the table changes. Replaced with `find_pia_id(feature_name)`.
- **The CI/CD deployment gate read Redis only**, treating a cache miss as "no PIA exists". Added a database fallback and an assertion that the gate still works after the cache is flushed.

### Notebook 3 — Anonymization Techniques
- **The k-anonymity demo did not achieve k-anonymity.** With generalization alone the smallest equivalence class was 1, yet the cell printed "k-Anonymity Applied" and captioned the group sizes "each combination appears at least k times" directly above output showing otherwise. Added suppression (the missing half of Samarati–Sweeney), a per-level trace showing why each level failed, a suppression rate (12% of the table), and an assertion that the *released* table really is k-anonymous.
- Added the failure before the fix: on the raw table, all 50 users are unique on (DOB, ZIP, city) — 100% re-identifiable — with a worked attacker lookup.
- **Quasi-identifiers were never enumerated honestly.** Added a demonstration that publishing one extra "harmless" column (`signup_month`) raises the records that must be suppressed to keep k=3 from 6 to 50, with the rule stated: k is a property of the whole release, not of the columns you happened to check.
- `load_user_data` now returns all 50 users rather than 20 — a smaller release has smaller equivalence classes, and k=3 was unreachable at 20 rows without suppressing 40% of the table.
- **l-diversity was checked against a dataset that was not k-anonymous.** It now runs on the released table, reports the majority-value share next to each verdict (one class is 80% `active` and still passes 2-diversity), notes that distinct l-diversity is the weakest variant and that l is bounded by the number of distinct sensitive values, and shows what l=3 would cost.
- **Differential privacy had no composition and no budget** — and cell 12 explicitly taught the averaging attack as a feature ("the AVERAGE of many DP queries converges to the truth… this is why DP works well at scale"), which is exactly what ε exists to prevent. Added a `PrivacyBudget` accountant with sequential/parallel composition, made the notebook show that printing one histogram at three epsilons costs ε=1.6, demonstrated the averaging attack recovering the true count at a cost of ε=10, and showed the budget refusing the 5th query. Replaced the bogus scaling claim with the correct one: Laplace noise does not shrink with n, *relative* error does.
- **`dp_average` derived its sensitivity from the data** (`max(values) - min(values)`), which leaks the extremes it is meant to hide, and was dead code. Rewritten as `dp_mean` with public bounds, clipping, and ε split between a noisy sum and a noisy count — and actually used.
- Seeded the RNG so the notebook tells the same story twice, and guarded `laplace_noise` against `random.random()` returning exactly 0.
- **"The data is now effectively anonymous — no longer personal data under GDPR" after deleting a token mapping.** It is not: the source record still exists, tokens still link rows, and the remaining columns still single people out. Reframed as crypto-shredding, with a linkage check showing how many tokenized records are unique on four columns nobody called PII.
- Comparison table gained a "what it does *not* protect against" column, and an honest closing note on what a real data release needs beyond these four techniques.

### Notebook 4 — Data Retention & Purging
- **The purge engine purged nothing.** Every seeded row was younger than its retention window, so Step 4 reported zeros, Step 5 ("Verify Anonymization") printed "no anonymized orders found", and the summary still claimed "'orders' count stays the same because we anonymized". Added a fixture step that ages rows past every policy (and resets them, so re-running is safe), plus assertions that each policy has work to do before the purge runs.
- **Every policy ran on `created_at`**, including "1 year after resolution" and "30-day grace period". Added a per-table retention clock (`resolved_at`, `deletion_requested_at`, `COALESCE(delivered_at, created_at)`) used identically by the scan and the purge. Added `users.deletion_requested_at` to `db/init.sql` (with an idempotent `ALTER` in the notebook for existing volumes): with a `created_at` clock an account deleted this morning is erased instantly and the grace period never happens. Asserted that accounts still inside the window survive.
- **The scan reported counts the purge would not act on** — fixed by applying the same filters in both.
- **Rows whose clock never starts are now surfaced**: an unresolved ticket from two years ago is kept forever by a policy that reads "one year after resolution".
- **Deleting the `users` row was called erasure.** The same name and address are duplicated into `orders.shipping_*`, the IP into `activity_log`, PII into ticket free-text; `ON DELETE SET NULL` left all of it behind, unlinked and unfindable. Added `purge_user_erasure()`, which scrubs every copy first, counts residual PII, and only then deletes — with assertions that residue is zero and that no orphaned order still carries a name.
- **`purge_anonymize` re-anonymized the same rows on every run** and logged them again, inflating the audit trail. Added an already-anonymized guard and switched the audited count from a pre-flight `COUNT(*)` to `cursor.rowcount`, so the log records what happened rather than what was predicted. Asserted idempotency.
- **The audit log could not answer "prove you erased *me*"** — it stored counts only. The erasure entry now carries the subject ids, what was scrubbed per table, and the residual check, with the Art. 17(3) tension written down rather than glossed.
- **`release_lock()` deleted the lock unconditionally**, so a run that overran its own TTL would free a different run's lock. Replaced with an atomic compare-and-delete, and made the run id microsecond-precise so two runs cannot share a token. Added mutual-exclusion assertions and an end-to-end idempotency assertion (the scheduled run immediately after the manual purge must process zero records).
- Takeaways now list what the notebook does *not* do: backups, replicas, WAL, CDC, search indexes, caches, warehouses, trained models, object storage, third-party processors, and legal hold.

### README
- Classification, retention and anonymization tables corrected to match the notebooks (DOB as RESTRICTED, the erasure clock, suppression, privacy budgets, tokens as personal data).
- Added a "What This Lab Demonstrates — and What It Doesn't" section: the PII scanner's measured recall, anonymization as demonstration rather than release process, the copies of data an erasure has to reach, and the absent legal-hold check.
