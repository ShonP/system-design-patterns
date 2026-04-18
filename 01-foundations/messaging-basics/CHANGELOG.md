# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Messaging Basics` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added notebooks: `01_queue_vs_pubsub`, `02_delivery_semantics`, `03_redis_pubsub`.
- QA pass:
  - NB1: added a "bad practice: direct synchronous calls" intro to motivate the broker, made `PubSub` thread-safe, and added a backpressure demo with a bounded queue and an ordering caveat.
  - NB2: added a "where does the dedup set live?" markdown (Redis SET, DB unique index, bloom filter) and a Transactional Outbox pattern explainer.
  - NB3: added a Redis **Streams** section showing replay (`XADD`/`XREAD` from `0-0`) and consumer groups (`XREADGROUP`/`XACK`/`XPENDING`) as the durable counterpart to fire-and-forget Pub/Sub.
  - All three notebooks executed end-to-end with `jupyter nbconvert --execute`.
