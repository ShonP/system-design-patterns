# Messaging Basics

> Part of `01-foundations/`. Pure-Python notebooks (1 and 2) plus an optional Redis demo (notebook 3) using Docker Compose.

## Learning objectives

- Distinguish point-to-point queues from pub/sub topics.
- Define at-most-once, at-least-once, exactly-once delivery semantics and which are practically achievable.
- Use idempotent consumers and dead-letter queues to make at-least-once safe.
- Use Redis Pub/Sub and feel its fire-and-forget limitations.

## Concepts covered

- Queues vs pub/sub
- Delivery semantics: at-most-/at-least-/exactly-once
- Idempotent consumers; dedup keys
- Dead letter queues
- Redis Pub/Sub (and what it is **not**)

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

- [`notebooks/01_queue_vs_pubsub.ipynb`](./notebooks/01_queue_vs_pubsub.ipynb) — build a queue (point-to-point) and a pub/sub bus from scratch with Python's stdlib.
- [`notebooks/02_delivery_semantics.ipynb`](./notebooks/02_delivery_semantics.ipynb) — at-most/at-least/exactly-once with a flaky simulated broker, plus a dead letter queue.
- [`notebooks/03_redis_pubsub.ipynb`](./notebooks/03_redis_pubsub.ipynb) — same idea over the network using Redis Pub/Sub; observe its fire-and-forget nature.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
