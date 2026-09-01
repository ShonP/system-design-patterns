# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-21 (correctness audit)

Seed data (`../siem/log_generator.py`, shared with labs 02 and 03):

- **Seeded the RNG.** The generator was unseeded, so two detections fired only
  probabilistically: `Outbound traffic to known malicious IP` spread 10 flows over 3
  random IPs and missed its threshold of 3 roughly **30%** of runs, and
  `Phishing email delivered` rolled a 70% block chance per mail, so all four were
  blocked and the rule never fired roughly **24%** of runs. Both now fire every time.
- **One campaign, one attacker IP.** Brute force picked a random suspicious IP and
  exfiltration picked another, while the detection rule hard-coded a third. The whole
  chain now runs from `185.220.101.42`, which makes it a genuine join key between
  `SigninLogs` and `AzureFirewall` — entity pivoting previously worked only by luck.
- **Added benign failed sign-ins** (1–4 per user). Normal traffic contained *zero*
  failed sign-ins, so the brute-force rule had no benign population to be wrong about
  and its precision was unfalsifiable: any threshold looked perfect. The compromised
  account is deliberately left typo-free so downstream labs can still attribute all of
  her failures to the campaign.
- **Timestamps are now spread over time.** Every row carried the same instant, so
  `ORDER BY timestamp` was an arbitrary tie-break and every `time_range_minutes` filter
  was a no-op distinction. Normal traffic spans the last ~55 minutes; the attack chain
  is laid down in kill-chain order (phish → brute force → lateral movement → exfil)
  inside the last ~13 minutes, tight enough to stay within the 60-minute rule windows.
  Also dropped the bogus `"Z"` suffix — the values are naive UTC and the server's own
  cutoffs carry no `Z`, so the two formats were being string-compared against each other.
- **Fixed the lateral-movement firewall rows.** All three "movements" logged the same
  hard-coded `10.0.1.10 → 10.0.2.10` flow regardless of the host actually being reached.
  Hosts now have addresses and each row points at its real destination.
- **"Large uploads" are now large.** Exfiltration printed "10 large uploads" while the
  rows carried no size field at all; uploads and firewall flows now carry
  `FileSizeBytes` / `BytesSent` (~800 MB total).
- **Fixed a MITRE ATT&CK mis-mapping.** The mimikatz rule was tagged `Execution`;
  mimikatz is T1003 OS Credential Dumping, so it is a **Credential Access** detection
  (which is how Sentinel's own Mimikatz rules are tagged). Renamed to
  `Credential dumping tool executed`. Added T-numbers to every rule description.
- **Seeding now self-checks.** It asserts all six shipped rules fire on the seeded
  attack, and that the brute-force rule fires on the compromised account *only*.

Notebook 1 — data ingestion:

- The KQL taught was `SigninLogs | where ResultType == "Failure"`, which is **invalid
  against real Sentinel**: `ResultType` is the Entra error code as a string (`"0"` =
  success, `"50126"`, `"53003"`, …) and there is no `"Failure"` value, so such a rule
  silently never fires. Replaced with `where ResultType != 0` plus a callout explaining
  the normalisation the mini-SIEM performs. (Lab 3 already taught the correct form; the
  two labs disagreed.)
- The failures-per-user chart flagged at `> 5` while the shipped rule fires at `>= 5`.
  Aligned, and the chart now shows the benign baseline it needs in order to mean anything.
- Added assertions: the seeded dataset is present with all four tables and six rules;
  the known-bad-IP firewall filter returns rows (it previously printed nothing at all
  when it matched nothing, which is indistinguishable from "found nothing suspicious");
  only the compromised account crosses the alerting threshold.

Notebook 2 — analytics rules:

- **The lab never measured precision.** Added a threshold sweep that scores the
  brute-force rule against ground truth derived from a signal the rule does not look at
  (external vs corporate source address): threshold 1 → **20% precision**, threshold 5 →
  **100%**, recall unchanged at 100%. Asserts that tuning improves precision *without*
  trading away recall.
- Corrected the bad→better→best framing. The prose promised "hundreds of alerts" from
  the naive rule; the engine emits one alert per rule run, so all three rules produce
  exactly one alert. The real difference — the only one that matters downstream — is
  that bad/better carry **no entity**, so no incident and no playbook can act on them.
  The cell now prints alerts/events/entity per rule and asserts exactly that.
- The over-broad → tuned demo now counts its own false positives (50% → 100% precision,
  4 alerts → 1) instead of asserting the improvement in prose, and asserts both that the
  over-broad rule really is noisy and that the tuned one still catches the threat.
- Fixed the ATT&CK coverage percentage: it counted every distinct tactic string on a
  rule without checking it was a real tactic, so a typo (`LateralMovment`) would have
  inflated coverage. Now intersects with the tactic enum and asserts no rule is tagged
  with a non-tactic.
- Made the resulting coverage gap a teaching point: tuning deleted the lab's only
  `Execution` rule and replaced it with a Credential Access one, which is exactly the
  kind of regression a coverage map exists to catch.

Notebook 3 — incidents and automation:

- **The opening diagram was false.** It showed three alerts about one user collapsing
  into one incident; `/incidents/correlate` groups on a byte-identical entity dict, and
  those alerts carry `{"UserPrincipalName": "alice@contoso.com"}`, `{}` and
  `{"AccountName": "alice"}` — three keys, three incidents. Rewrote the section around
  what the engine actually does, named the underlying problem (entity normalisation),
  and added a cell that **measures** the fragmentation (one campaign → 4 incidents) and
  asserts it, so the lesson fails loudly if correlation ever changes.
- **Removed a nondeterministic incident pick.** The investigation targeted "the first
  High-severity incident with entities", but every alert in the seed run is created
  within the same second, so the target was whichever row SQLite returned — while the
  triage comment, the manual runbook and the closing classification all say "brute
  force". Now selects the brute-force incident by name and asserts it has a user entity.
- The entity pivot printed the ten most recent endpoint rows, which are the bulk
  exfiltration uploads — the mimikatz and psexec executions, i.e. the entire point of
  the pivot, never appeared in the output. Flagged tooling is now shown first.
- Added assertions: triage persists; the pivot really does surface attacker tooling the
  analyst was not alerted about; a playbook actually matches and runs (it previously
  printed "No matching playbooks" and carried on); the TI watchlist matches something;
  a closed incident carries both a status and a classification.
- Replaced "this is exactly what Microsoft Sentinel does" with a table of the six things
  the mini-SIEM deliberately does not do, and a note that the notebook leaves three
  incidents from the same campaign open — which is what fragmented correlation costs.

Lab README:

- Documented the deterministic seed, what the seeded environment actually contains, and
  the correlation limitation, instead of implying Sentinel parity.
