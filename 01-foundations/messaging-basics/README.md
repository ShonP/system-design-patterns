# Messaging Basics

> Part of `01-foundations/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Learning objectives

- Distinguish point-to-point queues from pub/sub topics and from brokered service buses.
- Define at-most-once, at-least-once, exactly-once delivery semantics and which are practically achievable.
- Reason about message ordering guarantees and why partition keys matter.
- Compare synchronous request/response with asynchronous messaging.

## Concepts covered

- Queues vs pub/sub vs service bus
- Delivery semantics: at-most/at-least/exactly-once
- Idempotent producers/consumers; de-duplication keys
- Message ordering and partition keys
- Sync vs async communication patterns

## Planned notebooks

> These are planned; files do not yet exist. Following the repo convention, each will be added as a separate numbered notebook (`NN_*.ipynb`) without renumbering earlier ones.

- `notebooks/01_queue_vs_pubsub.ipynb`
- `notebooks/02_delivery_semantics_demo.ipynb`
- `notebooks/03_idempotent_consumers.ipynb`
- `notebooks/04_partition_keys_and_ordering.ipynb`

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
