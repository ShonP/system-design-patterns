# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
- Added Notebook 5: `05_lwt_ttl_and_anti_patterns.ipynb` covering lightweight transactions (LWT / `IF NOT EXISTS` / Paxos), TTL, counters, same-partition vs. multi-partition batches, secondary-index pitfalls, driver paging, and a production tuning cheat sheet.
- Added inline "production note" callouts in Notebook 1 (SimpleStrategy vs. NetworkTopologyStrategy), Notebook 2 (wide-row size limits), Notebook 3 (LWT / SERIAL pointer), and Notebook 4 (tombstone-queue anti-pattern).
- Expanded README's "Key Concepts Covered" with LWT, TTL, and a short anti-patterns section; added Notebook 5 to the table of contents.
