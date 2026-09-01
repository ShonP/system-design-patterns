# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (repo-wide verification pass)
- **Fix**: `AS token` is a syntax error -- `token` is a reserved word in CQL. Notebook 1's partition-token queries now alias to `partition_token`; notebook 5's `session_tokens` table column is renamed accordingly.
- **Fix**: node2 and node3 reported healthy while the ring still had a single member, because the healthcheck `nodetool status | grep -q '^UN'` matches the node's own line the moment it boots. `docker compose up --wait` therefore returned with one node up and every QUORUM operation failed with *"Cannot achieve consistency level QUORUM"*. The checks are now monotonic: node2 requires 2 UN nodes, node3 requires 3.
- **Fix**: a freshly-bootstrapped ring transiently rejects queries against just-created tables with `INCOMPATIBLE_SCHEMA`, and LWT/Paxos can exceed the driver's 10s default. The notebooks now wait for schema agreement after DDL, retry those two transient failures, and raise the client timeout -- so the lab works from a cold `docker compose up` rather than only after the cluster has settled.
- Fixed a garbled markdown line in notebook 5 (`**Session  expire after 24 hourstokens**`).
- All 5 notebooks now execute end-to-end from a cold start (previously 2 of 5 failed).

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
- Added Notebook 5: `05_lwt_ttl_and_anti_patterns.ipynb` covering lightweight transactions (LWT / `IF NOT EXISTS` / Paxos), TTL, counters, same-partition vs. multi-partition batches, secondary-index pitfalls, driver paging, and a production tuning cheat sheet.
- Added inline "production note" callouts in Notebook 1 (SimpleStrategy vs. NetworkTopologyStrategy), Notebook 2 (wide-row size limits), Notebook 3 (LWT / SERIAL pointer), and Notebook 4 (tombstone-queue anti-pattern).
- Expanded README's "Key Concepts Covered" with LWT, TTL, and a short anti-patterns section; added Notebook 5 to the table of contents.
