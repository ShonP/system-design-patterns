# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20
- Rewrote `README.md` as a self-contained **paper guide** for Amazon S3, replacing the scaffolding
  stub. Removed the "planned notebooks" section: this lab is documentation-only by design.
- Corrected the stub's central implicit claim: **S3 has no canonical academic paper.** The guide now
  cites the real primary sources — Andy Warfield's *Building and operating a pretty big storage
  system called S3* (All Things Distributed / USENIX FAST '23 keynote, 2023), the ShardStore paper
  (Bornholt et al., SOSP 2021), and the AWS consistency and performance documentation — and flags
  explicitly which statements are attributable versus inferred.
- Added an ASCII diagram of the flat keyspace, the range-partitioned index and the erasure-coded
  storage layer; a core-design walkthrough; a decisions-and-costs table; a lineage section (the S3
  API as a de facto standard, the lakehouse table formats, storage/compute separation); verified
  cross-links; and a reading guide.
- Fact-checked figures: strong read-after-write consistency for all GET/PUT/LIST since 1 December
  2020 (it was eventual for overwrites, deletes and LIST before that); at least 3,500 write and
  5,500 read requests per second per partitioned prefix; eleven-nines durability design target;
  S3 Standard spanning at least three availability zones; and Warfield's July 2023 figures of over
  280 trillion objects and over 100 million requests per second.

## 2026-04-18
- Scaffolded `S3` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
