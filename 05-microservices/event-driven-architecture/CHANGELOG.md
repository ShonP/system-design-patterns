# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19 (later)
- Added `04_reliability_patterns.ipynb` covering three production-reliability patterns with runnable bad→best demos:
  - **Transactional Outbox** — fix the dual-write problem by writing events to an `outbox` table in the same DB transaction and letting a relay publish them.
  - **Saga with compensation** — a generic `SagaStep`/`run_saga` runner that executes forward steps and rolls back in reverse on failure.
  - **Dead-Letter Queue** — bound retries per message and divert poison messages so the main queue keeps flowing.
- Added a "Beyond e-commerce" table with real-world EDA examples across SaaS, ride-sharing, IoT, banking, gaming, and healthcare.
- Updated `README.md` concept list and notebook index.

## 2026-04-19
- Rewrote `01_introduction.ipynb` with a coffee-shop analogy, clearer bad→best progression, and a decoupling demo.
- Rewrote `02_worked_example.ipynb`: replaced the racy `deque`-based worker with a thread-safe `queue.Queue`, added a synchronous-bus failure demo, explicit fault-isolation proof, and a benefits/costs cheatsheet.
- Added `03_schema_and_delivery.ipynb` covering events vs commands, additive schema evolution, at-least-once + idempotent consumers (with `event_id` dedup), and broker-vs-mediator topology — plus a mapping to real brokers (Kafka, RabbitMQ, SNS/SQS, Redis Streams, Temporal, Step Functions).
- Updated `README.md` concept list to match what the notebooks actually teach.

## 2026-04-18
- Scaffolded `Event Driven Architecture` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_introduction.ipynb, 02_worked_example.ipynb.
