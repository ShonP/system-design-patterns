# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (review pass)
- NB1: capacity cell now reports storage in PB/EB rather than an unreadable
  "3000000 GB", and adds daily growth, attachment dedup savings, index size, and a
  server count. The takeaways said "hundreds of thousands of QPS" while the code
  computed ~13.9M peak reads/sec — corrected.
- NB2: added a v3 threading step. The previous "better" version only followed
  `in_reply_to` / the last `Reference`, so a mailbox missing an intermediate reply fell
  through to subject matching; and the subject fallback let a stranger join a thread
  (the notebook pointed this out but never fixed it). v3 walks the whole `References`
  chain newest→oldest and gates the subject fallback on participant overlap and
  non-generic subjects, with assertions covering all three cases.
- NB3: the search benchmark compared a naive scan for `"quarterly"` (0 hits, 6 ms)
  against an indexed lookup of a completely different query (50k hits). Both now run
  the identical query, assert identical hit sets, and report the real speed-up, plus
  index build time and the honest costs of maintaining a second copy of the truth.

## 2026-04-20
- Rewrote all three notebooks with explicit **bad → best** progression.
- **Notebook 1**: added runnable back-of-the-envelope capacity estimation, SPF/DKIM/DMARC section, and a trade-off table justifying architectural choices.
- **Notebook 2**: added RFC 5322 threading builder, subject normalization, cursor pagination demo, MIME parsing with stdlib `email`, Pydantic validation example, and idempotent-send discussion.
- **Notebook 3**: fixed SMTP state-machine DATA termination (`.` line), added exponential-backoff retry simulator, linear-scan → inverted-index search benchmark, storage-tier cost simulator, and attachment content-hash dedup example.
- Added `pydantic[email]` dependency so `EmailStr` validation works.

## 2026-04-18
- Scaffolded `Gmail` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
