# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Hinted Handoff` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added notebook 1 (forward-and-forget) and notebook 2 (hinted handoff).
- QA pass: rewrote notebooks 1 and 2 with beginner-friendly analogies, clearer bad→good progression, and a last-write-wins edge-case test. Added notebook 3 covering hint TTL expiry, coordinator crash, sloppy quorum, and when to fall back to anti-entropy repair. Verified all notebooks execute cleanly via `jupyter nbconvert --execute`.
