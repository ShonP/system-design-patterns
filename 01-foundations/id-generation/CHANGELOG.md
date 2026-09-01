# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Distributed ID Generation` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added Notebook 1 (`01_why_id_generation_is_hard.ipynb`): BAD/BETTER/BEST progression with B-tree locality demo.
- Added Notebook 2 (`02_uuid_ulid_ksuid_compared.ipynb`): from-scratch UUIDv4/v7, ULID, KSUID + monotonic ULID + pydantic validator.
- Added Notebook 3 (`03_snowflake_id_generator.ipynb`): 64-bit Snowflake generator with sequence-overflow and clock-skew handling.
- QA pass: verified all notebooks execute end-to-end.
- Added Notebook 4 (`04_production_patterns.ipynb`): worker-ID assignment, DB storage trade-offs, decoding a real Discord snowflake, NanoID, production gotchas.
- Updated Notebook 2 cheat sheet to mention NanoID.

## 2026-08-20 (correctness audit)
- NB1: fixed the toy B-tree. Its page-selection rule sent *every* sequential insert to
  page 0, so pages held overlapping key ranges and the "1 page load" result was an
  artefact. Pages are now disjoint sorted ranges (asserted), and the honest result is
  249 vs 1928 page loads (7.7x).
- NB2: corrected the UUIDv4 collision claim ("more IDs than stars in the observable
  universe" is false — 2^61 ≈ 2.3e18 vs ~1e22 stars). Added assertions for the UUIDv7
  version/variant/timestamp fields, and turned every "sorted == creation order?" print
  into an assertion. Made the KSUID k-sortability claim testable in both directions:
  a same-second burst must *not* sort, a burst >1 s apart must.
- NB3: asserted the 41+10+12 bit layout fills exactly 63 bits, asserted the decoder
  round-trips at every field boundary, and asserted sequence rollover (4096 IDs in one
  ms, then a forced wait for the next ms).
  **Added a demo of the clock-rewind failure**: the unguarded generator silently
  re-issues three IDs it had already handed out. Fixed a TOCTOU in
  `ClockSafeSnowflake`, which checked the clock and then released the lock before
  generating; it now holds the (reentrant) lock across the whole operation.
- NB4: `worker_from_pod_ordinal()` read the real `HOSTNAME` and raised on any machine
  whose hostname doesn't end in a digit — now takes the pod name as an argument.
  Corrected the NanoID collision table (16 chars is ~40 trillion IDs, not ~10) and
  added a cell that checks the table against the birthday bound. Asserted the Discord
  snowflake round-trips and noted that Discord spends all 64 bits, unlike Twitter's 63.
- Hygiene: kernelspec set to `Python 3 (.venv)` on NB4.
