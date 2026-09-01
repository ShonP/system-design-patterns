# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Hinted Handoff` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added notebook 1 (forward-and-forget) and notebook 2 (hinted handoff).
- QA pass: rewrote notebooks 1 and 2 with beginner-friendly analogies, clearer bad→good progression, and a last-write-wins edge-case test. Added notebook 3 covering hint TTL expiry, coordinator crash, sloppy quorum, and when to fall back to anti-entropy repair. Verified all notebooks execute cleanly via `jupyter nbconvert --execute`.

## 2026-08-20
- Added the **size cap** the lab previously only implied: a TTL bounds how *old* a hint gets,
  not how *many* there are, and an unbounded buffer in front of a dead replica takes the
  coordinator down with it. Overflow behaviour is explicit and asserted.
- **Bug fix:** the sloppy-quorum coordinator reused the same stand-in for several down replicas,
  so `W` acks could be backed by fewer physical copies than claimed. Stand-ins must now be
  distinct, with a demo of what happens when there are not enough.
- Added assertions for convergence after handoff, TTL expiry leaving a permanently stale
  replica, and coordinator-crash data loss.
