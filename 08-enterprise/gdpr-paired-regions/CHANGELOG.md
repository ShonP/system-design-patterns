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

## 2026-08-21 (correctness audit)

Content-correctness pass across all four notebooks and the README. This lab makes
legal-adjacent claims, so the emphasis was on accuracy and on not overclaiming.
Several defects executed cleanly and printed reassuring ✅ output, which is
exactly why they survived.

### Legal accuracy

- **"GDPR requires EU data to stay in the EU" — removed everywhere.** GDPR contains
  no localisation mandate; Chapter V (Art. 44–50) restricts *transfers to third
  countries*. In-region storage is now presented as an engineering strategy that
  avoids Chapter V work, with real localisation mandates attributed to their actual
  sources (national law, sector regulators, contracts). README, NB1 §2, NB1 takeaways.
- **"EU citizens" → data subjects.** GDPR applies by Article 3 territorial scope, not
  nationality. Corrected in README, NB1 §5, NB3 §1, NB4.
- **Pseudonymisation vs anonymisation (NB3 §4, was "The Anonymization Pattern").**
  The old `anonymize_user()` set `email = 'deleted_user_{id}@anonymized.local'`
  (embedding the row id), kept the primary key, left `addresses`/`orders`/
  `consent_log` joined on `user_id`, retained country and signup timestamp — then
  printed *"User is now statistically invisible"*. That is pseudonymisation, and
  pseudonymised data is still personal data (Recital 26). Section rewritten around
  the Art. 4(5) / Recital 26 distinction; the function is renamed
  `pseudonymise_user()`, no longer derives the pseudonym from the id, deletes
  addresses rather than string-redacting them, de-links orders, and applies the
  *same* pseudonym in every region. The notebook now **grades its own output**
  against the Art. 29 WP 05/2014 three-part test (singling out / linkability /
  inference), computes the k-anonymity of the retained quasi-identifiers, and
  concludes NOT ANONYMOUS.
- **Art. 17 is conditional, not a delete button.** Added the Art. 17(1) grounds and
  the Art. 17(3) exemptions, scoped "to the extent necessary".
- **"30 days" → Art. 12(3) one month**, extendable by two further months on notice.
  Retention periods de-mythologised (7 years is not "most EU countries": ~6 IE,
  7 NL, 10 DE/FR).
- **PSD2 / "EU HIPAA" / "Germany requires data in-country" claims removed** (NB1 §4).
  None of them mandate localisation; replaced with EBA/DORA outsourcing, Art. 9(4)
  member-state conditions, and §203 StGB.
- **British Airways £20m ICO fine (NB4 §7) was backwards.** The lab said BA was
  fined partly for notifying too late. The penalty was for inadequate *security*;
  prompt notification was a **mitigating** factor that reduced it from £183m. The
  timing criticism was that BA did not *detect* the attack for two months.
- **"Azure is pre-certified for GDPR" removed** (NB4 §8). No such thing — Art. 42
  certification needs an approved scheme and accredited body, and Art. 42(4) says
  it does not reduce controller responsibility. Replaced with what Microsoft
  actually offers (ISO 27001/27701, SOC, DPA commitments, EU Data Boundary).
- Consent reframed as **one lawful basis of six** (NB4 §3). "Consent rate" is no
  longer treated as a health metric; the report now checks that every logged
  *purpose* has a declared lawful basis, and asserts on it.
- Product names corrected: "Azure Data Map"/"Azure Purview" → **Microsoft Purview**.
  Switzerland removed from the EU/EEA routing table (it is adequacy, not EEA) and
  given an explicit `ADEQUACY_COUNTRIES` entry with an assertion.

### Azure facts (verified against Microsoft Learn, not the prose)

- **"Data never leaves the geography" — the central overclaim — corrected.**
  Microsoft's wording is *"almost all* regions reside within the same geography as
  their pair", and the documented exception is **Brazil South ↔ South Central US**
  (asymmetric, cross-geography). Also surfaced: *"a small number of Azure services
  use these region pairs"*, and *"deploying resources to a region in a pair doesn't
  automatically make them more resilient, nor does it provide automatic high
  availability, disaster recovery capabilities, or failover."* README, NB1 §2,
  NB2 §1/§5.
- **Region pair table corrected and extended**: added Sweden Central ↔ Sweden South,
  Norway, Switzerland; marked restricted-access secondaries; listed the **unpaired**
  European regions (Austria East, Belgium Central, Denmark East, Italy North,
  Poland Central, Spain Central).
- **Fabricated "Azure's Guarantees" table replaced** (NB2 §5). "RPO < 5 seconds,
  RTO < 30 minutes" is not an Azure figure. Now per-service and sourced: Azure SQL
  failover groups RTO *typically < 60 s* and RPO stated as *"equal to or greater
  than 0"*; geo-restore *minutes or hours*; GRS typically < 15 min with **no SLA**.
  Sequential updates softened to Microsoft's own "strives to stagger".
- **Spotify "Stockholm + Ireland pairing" removed** — Sweden Central pairs with
  Sweden South, and Spotify runs on Google Cloud. The named-company table was
  replaced with architecture patterns, with the retraction kept visible.
- Amsterdam→Dublin distance corrected (~1000 km → ~750 km) with a realistic RTT.

### Correctness defects (code did not do what the prose said)

1. **NB1 cell 11 — "Each user's data exists ONLY in their assigned region" was false.**
   The verification only queried the two rows the demo had just written, while
   `init.sql` loads all 15 seed users into *both* containers. Replaced with a
   narrowly-asserted check of the two new users **plus** a new full-table residency
   scan that reports how many people are in both regions and explains why.
2. **NB1 cell 8/9 — prose described a US database, code wrote to eu-west.** Markdown
   rewritten to match what the code actually proves (a routing bug), with the
   Chapter V consequence explained rather than faked. Added
   `where_does_this_row_live()` and assertions that the anti-pattern really misroutes.
3. **NB2 cell 5 — replication silently dropped columns.** `ON CONFLICT DO UPDATE` only
   carried `full_name` and `phone`, so a **consent withdrawal never replicated**: the
   primary showed consent revoked while the replica still said TRUE. All replicated
   columns now propagate, with a per-column equality assertion after replication.
4. **NB2 — the async data-loss window was claimed but never demonstrated.** New
   §3b writes two users, replicates one, "destroys" the region, fails over, and
   shows the other is gone — a user who got a 200 OK for an account that no longer
   exists. Asserted in both directions. RPO reported in records.
5. **NB2 cell 11 — the failover was a boolean flip and `health_check()` was never
   called.** `get_active_region()` now derives the answer from an actual probe;
   `simulate_failure()`/`simulate_recovery()` assert the probe flips.
6. **NB2 cell 11 — failover rewrote `home_region` to the active region**, so a German
   customer written during an outage was permanently relabelled `eu-north` —
   corrupting the exact field NB4 audits. `write_user()` now takes the jurisdiction
   from the geo-router; asserted that all three test writes keep their label.
7. **NB3 — cross-region erasure keyed on a per-database `SERIAL` id.**
   `full_gdpr_erasure(user_id=2, ...)` ran `DELETE WHERE id = 2` against both
   regions and only worked because both containers were seeded identically. Once
   the sequences drift this **erases an innocent third party in the replica while
   leaving the requester intact** — silently, and symmetrically. Everything now
   keys on email via `resolve_local_user_id()`, and a new cell proves the ids drift
   and names who would have been wrongly deleted.
8. **NB3 — erasure never demonstrated the replica gap.** The old flow deleted from
   both regions in lockstep and verified only the primary. Now the primary is erased
   *first, on purpose*, and the notebook shows the replica still holding name, phone,
   DOB and address while `erasure_requests.status` already says `completed`.
   Asserted. Added `verify_erased_everywhere()` as an **independent** re-query, so
   the delete routine can no longer certify itself.
9. **NB3 — backups were listed as a problem and never touched.** New §3b models a
   nightly snapshot, shows the erased subject surviving in it, runs a naive restore
   that **resurrects him fully**, then builds an HMAC-based **suppression list** and
   re-runs the same restore with him correctly excluded. Both outcomes asserted.
   Covers put-beyond-use, retention-window expiry, and the paradox that reliable
   forgetting requires permanently remembering that you forgot.
10. **NB4 cell 6 — the violation detector audited a self-reported label, not the
    data.** It compared `country_code` against the row's own `home_region` column
    and never looked at which database answered. A Swedish row sitting in eu-west
    whose `home_region` honestly said `eu-north` passed clean — as would a row in a
    US database. Rewritten to take three separate inputs (physical placement,
    routing policy, the label) and emit four outcomes: `CROSS_GEOGRAPHY` (CRITICAL),
    `MISROUTED`, `MISLABELLED`, and informational `REPLICATED`. Cell 7 is now a test
    suite planting all three cases — including the one the old detector missed —
    with assertions. Logic verified out-of-band against five scenarios.
11. **NB4 — nothing ever checked whether erasures actually finished.** New §2b
    cross-checks every `completed` erasure request against live data in every
    region, flags residue, un-closed requests, and regions where no request was ever
    raised. Includes a self-test that plants the exact NB3 failure state and asserts
    the audit catches it.
12. **NB4 cell 4 — the residency map keyed on `user_id` and merged/split people.**
    After a one-region pseudonymisation it listed Hans Müller twice. Now keyed on
    email, records the per-region local id, and **flags field-level divergence**
    instead of silently keeping whichever value it read first.
13. **NB4 §6 — "COMPLIANCE SCORE: 92/100 (Grade: A) — well-prepared for a GDPR
    audit."** Averaging conjunctive controls let three passes hide one failure; in
    the original run the residency check reported ✅ *while a data subject who had
    requested erasure was still in the replica*. Replaced with a **technical controls
    report**: named checks, explicit per-check scope, PASS/FAIL/NOT ASSESSED, any
    FAIL fails the whole report, no score and no grade, and a mandatory closing list
    of the ~12 things it did not assess. Asserts internal consistency.
14. Unordered `LIMIT 3` in NB2 made replication pick different users per run —
    added `ORDER BY id`. Failover and RPO demos now purge before running so re-runs
    are idempotent.

### Assertions added

Every section that demonstrates a failure now fails loudly if it stops
demonstrating it: misrouting really misroutes (NB1); unmapped and adequacy
countries are refused (NB1); the seed really exists in both regions (NB1);
replication is column-complete (NB2); the in-flight write is really lost and the
replicated one really survives (NB2); health probes really flip and labels really
survive failover (NB2); the naive DELETE really strands PII (NB3); the legal-hold
branch really fires (NB3); the replica really still holds the erased subject
(NB3); the backup really retains her and the suppression list really excludes her
(NB3); the pseudonymised row is really still singled out (NB3); access and erasure
cover the same tables (NB3); all three planted residency violations are caught with
the right types and severities (NB4); the erasure audit catches a planted false
"completed" (NB4); every logged purpose has a lawful basis (NB4); the 72-hour clock
is correct at 0/59/71/72/73 hours — the old code had no boundary test (NB4).

### Scope honesty

- README gained a **"What This Lab Is Not"** section: no compliance is conferred by
  code, this is not legal advice, two Postgres containers are not Azure, the threat
  model (encryption, TLS, access control, read logging, tenancy) is entirely absent,
  and backups are simulated.
- NB2 no longer claims failover keeps data in the EU without noting that *access*
  from outside the EU is a transfer too, and that failback is not implemented.
- NB3 is explicit that `erasure_requests` retains a plaintext email indefinitely in
  both regions, and offers the HMAC/retention alternatives.
- NB4 §8 adds the point that **prevention beats detection** — Azure Policy
  `allowedLocations` denies the misplacement; `detect_violations()` only notices it
  after the infringement has occurred.

### Not changed (and why)

- **The two-container topology.** Replication stays application-level and hand-rolled
  so the RPO window and the erasure gaps remain visible and breakable. Called out in
  the README instead.
- **No third (non-EU) database.** The `CROSS_GEOGRAPHY` branch is exercised by
  injecting a hypothetical `us-east` placement into the detector rather than by
  deploying another container, so the check is tested without expanding the lab.
- **`consent_given` stays a boolean.** Modelling per-purpose lawful bases properly
  would need a schema change; instead the lawful-basis map lives in NB4 with an
  assertion that no logged purpose is missing from it.
- **Encryption, key management, access control and read auditing** are still absent.
  They belong in a security lab; the README now says so rather than leaving the
  omission implicit.
