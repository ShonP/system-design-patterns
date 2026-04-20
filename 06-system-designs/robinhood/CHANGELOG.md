# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Switched `docker-compose.yml` Kafka image from the unavailable
  `bitnami/kafka:3.7` to `confluentinc/cp-kafka:7.6.0` (KRaft mode), matching
  the ad-click-aggregator lab and the `03-technologies/messaging/kafka` lab.
- Notebook 1 — added two bad→best sections with runnable demos:
  1. "Money Should Never Be a `float`" (float drift vs integer cents).
  2. "Idempotency Keys for Order Placement" (retry creates duplicate order
     vs `client_order_id` + `UNIQUE` index de-dup).
- Notebook 2 — added a bad→best timing demo that compares recomputing
  positions by scanning every trade (`O(n)`) against reading the
  materialized `positions` table (`O(1)`).
- Notebook 3 —
  - replaced deprecated `datetime.utcnow()` with `datetime.now(timezone.utc)`;
  - made Kafka consumer `group_id`s unique per run so re-executing the
    notebook isn't affected by committed offsets from earlier runs;
  - added a bad→best "Polling vs Pub/Sub" section that measures request
    volume and price-change latency for both approaches.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
