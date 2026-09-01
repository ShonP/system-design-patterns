# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20
- Rewrote `README.md` as a self-contained **paper guide** for *The Google File System* (Ghemawat,
  Gobioff, Leung — SOSP '03), replacing the scaffolding stub. Removed the "planned notebooks"
  section: this lab is documentation-only by design.
- Added full citation with a link to the canonical PDF, an ASCII architecture diagram in the repo's
  house style, a core-design walkthrough (single master, 64 MB chunks, leases, decoupled data flow,
  atomic record append, the consistent/defined/undefined consistency model, fault tolerance), a
  decisions-and-costs table, a lineage section (HDFS, Bigtable, Chubby, Colossus), verified
  cross-links to labs in this repo, and a 20-minute reading guide.
- Fact-checked every figure against the paper text: 64 MB chunks, 64-bit chunk handles, three
  replicas by default, under 64 bytes of master metadata per chunk, 60-second initial lease,
  at-least-once record append, 64 KB checksum blocks with 32-bit checksums, three-day lazy GC.

## 2026-04-18
- Scaffolded `Gfs` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
