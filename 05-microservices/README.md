# Microservices

Microservices-specific patterns — communication, resilience, composition,
and lifecycle — sourced primarily from
[*Grokking Microservices Design Patterns*](https://www.designgurus.io/course/grokking-microservices-design-patterns).

## Labs in this section

| Lab | Pattern |
|---|---|
| [`api-gateway/`](./api-gateway/) | Edge service fronting a set of microservices |
| [`bff/`](./bff/) | Backend-for-Frontend — one gateway per client type |
| [`service-discovery/`](./service-discovery/) | Finding healthy service instances at runtime |
| [`sidecar/`](./sidecar/) | Out-of-process helper bundled with a service instance |
| [`circuit-breaker/`](./circuit-breaker/) | Fail fast when a downstream is unhealthy |
| [`bulkhead/`](./bulkhead/) | Isolate resource pools to contain failures |
| [`retry/`](./retry/) | Safely retrying transient failures |
| [`saga/`](./saga/) | Multi-service transactions without 2PC |
| [`cqrs/`](./cqrs/) | Split read and write models |
| [`event-driven-architecture/`](./event-driven-architecture/) | Services communicating via events |
| [`strangler/`](./strangler/) | Incrementally replacing a legacy system |
| [`configuration-externalization/`](./configuration-externalization/) | Keeping config out of the binary |

Every lab follows the same skeleton: `README.md`, `references/designgurus.md`,
`CHANGELOG.md`. Notebooks will be added incrementally — see each lab's
README for the notebook plan.

See also:
- [`../docs/restructure-proposal.md`](../docs/restructure-proposal.md) — overall repo structure
- [`../docs/content-map.md`](../docs/content-map.md) — lesson → lab mapping
