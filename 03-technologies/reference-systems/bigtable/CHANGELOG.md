# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20
- Rewrote `README.md` as a self-contained **paper guide** for *Bigtable: A Distributed Storage
  System for Structured Data* (Chang, Dean, Ghemawat, Hsieh, Wallach, Burrows, Chandra, Fikes,
  Gruber — OSDI '06), replacing the scaffolding stub. Removed the "planned notebooks" section: this
  lab is documentation-only by design.
- Added full citation with the canonical PDF, ASCII diagrams for the data model and the
  LSM write path, a core-design walkthrough (row/column/timestamp map, column families and locality
  groups, tablets, the three-level Chubby → root → METADATA location hierarchy, master vs. tablet
  servers, SSTables and the three compaction types, the five ways Chubby is load-bearing, and the
  §6 refinements), a decisions-and-costs table, a lineage section, verified cross-links, and a
  reading guide.
- Fact-checked against the paper text: row keys up to 64 KB (10–100 bytes typical), tablets
  ~100–200 MB by default, ~1 KB per METADATA row with 128 MB METADATA tablets, 64 KB SSTable
  blocks, five-replica Chubby cell.
- Stated explicitly what Cassandra inherited from Bigtable (storage engine and data model) versus
  from Dynamo (ring, replication, gossip) — a distinction the stub did not make.

## 2026-04-18
- Scaffolded `Bigtable` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
