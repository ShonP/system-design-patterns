# Messaging Basics

> Part of `01-foundations/`. Pure-Python notebooks (1 and 2) plus an optional Redis demo (notebook 3) using Docker Compose.

## Learning objectives

- Feel the pain of direct synchronous calls and understand why a broker decouples services.
- Distinguish point-to-point queues from pub/sub topics.
- Define at-most-once, at-least-once, exactly-once delivery semantics and which are practically achievable.
- Use idempotent consumers and dead-letter queues to make at-least-once safe.
- Use Redis Pub/Sub and feel its fire-and-forget limitations, then upgrade to Redis Streams for durability and replay.

## Concepts covered

- Direct calls vs message brokers (the bad → good progression)
- Queues vs pub/sub
- Backpressure with bounded queues
- Ordering caveats with multiple workers / retries
- Delivery semantics: at-most-/at-least-/exactly-once
- Idempotent consumers; where the dedup state lives (Redis SET, DB unique index, bloom filters)
- Transactional Outbox pattern (producer-side reliability)
- Dead letter queues
- Redis Pub/Sub (and what it is **not**)
- Redis Streams: replay (`XADD`/`XREAD`) and consumer groups (`XREADGROUP`/`XACK`/`XPENDING`)

## Setup

```bash
cd 01-foundations/messaging-basics
uv sync
```

For notebook 3 you also need Redis:

```bash
docker compose up -d
```

Stop it with `docker compose down` when done.

Open any notebook in VS Code and select the `.venv` kernel from the kernel picker (top-right of the notebook). If the kernel doesn't show up, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_queue_vs_pubsub.ipynb`](./notebooks/01_queue_vs_pubsub.ipynb) — start with the bad practice (direct sync calls), then build a queue and a pub/sub bus from scratch with stdlib; finish with backpressure via a bounded queue.
- [`notebooks/02_delivery_semantics.ipynb`](./notebooks/02_delivery_semantics.ipynb) — at-most/at-least/exactly-once with a flaky simulated broker, idempotent consumers, dead-letter queue, plus notes on dedup-state storage and the transactional outbox pattern.
- [`notebooks/03_redis_pubsub.ipynb`](./notebooks/03_redis_pubsub.ipynb) — Redis Pub/Sub (fire-and-forget) over the network, then upgrade to Redis Streams with consumer groups for durable, replayable, ack-based delivery.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
