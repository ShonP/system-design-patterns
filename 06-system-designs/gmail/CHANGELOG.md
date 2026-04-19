# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Rewrote all three notebooks with explicit **bad → best** progression.
- **Notebook 1**: added runnable back-of-the-envelope capacity estimation, SPF/DKIM/DMARC section, and a trade-off table justifying architectural choices.
- **Notebook 2**: added RFC 5322 threading builder, subject normalization, cursor pagination demo, MIME parsing with stdlib `email`, Pydantic validation example, and idempotent-send discussion.
- **Notebook 3**: fixed SMTP state-machine DATA termination (`.` line), added exponential-backoff retry simulator, linear-scan → inverted-index search benchmark, storage-tier cost simulator, and attachment content-hash dedup example.
- Added `pydantic[email]` dependency so `EmailStr` validation works.

## 2026-04-18
- Scaffolded `Gmail` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
