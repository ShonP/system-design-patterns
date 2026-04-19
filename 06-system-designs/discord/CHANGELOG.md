# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19
- Rewrote all three notebooks with runnable bad→best demos:
  - N1: capacity calculator; gateway sharding (random vs modulo vs consistent hashing).
  - N2: Snowflake ID generator; offset vs cursor pagination; pydantic gateway events; heartbeat timeout; session resume with sequence numbers; nonce-based idempotency.
  - N3: fan-out (broadcast vs pub/sub topic); naive vs lazy presence; token-bucket rate limiter; TCP-vs-UDP voice stutter simulation; SFU explanation.
- All notebooks execute end-to-end with only pydantic as a runtime dependency.

## 2026-04-18
- Scaffolded `Discord` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
