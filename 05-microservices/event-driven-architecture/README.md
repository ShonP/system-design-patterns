# Event Driven Architecture

> Part of the `05-microservices/` series. Includes runnable notebooks and references.

## Overview

Building services that communicate via events.

## Concepts covered

- Request-driven vs event-driven (tight vs loose coupling)
- A tiny in-memory event bus (sync → async → fault-isolated)
- Events (facts) vs commands
- Schema evolution — adding fields without breaking consumers
- At-least-once delivery and idempotent consumers
- Broker vs Mediator topology (with a hybrid note)
- Mapping our toy bus to Kafka / RabbitMQ / SNS-SQS / Redis Streams

## Setup

```bash
cd 05-microservices/event-driven-architecture
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_introduction.ipynb`](./notebooks/01_introduction.ipynb) — Request-driven vs event-driven with a coffee-shop analogy, plus the minimal event bus.
- [`notebooks/02_worked_example.ipynb`](./notebooks/02_worked_example.ipynb) — Upgrade to an async, fault-isolated bus; add features without touching the producer.
- [`notebooks/03_schema_and_delivery.ipynb`](./notebooks/03_schema_and_delivery.ipynb) — Events vs commands, schema evolution, idempotency for at-least-once delivery, and broker-vs-mediator topology.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
