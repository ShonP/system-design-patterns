# Patterns

Scaling and reliability patterns. Each lab focuses on one recurring problem
and shows several ways to solve it, from naive to production-grade.

## Labs in this section

| Lab | Problem |
|---|---|
| [`scaling-reads/`](./scaling-reads/) | Read-heavy workloads |
| [`scaling-writes/`](./scaling-writes/) | Write-heavy workloads |
| [`dealing-with-contention/`](./dealing-with-contention/) | Concurrent updates on the same resource |
| [`real-time-updates/`](./real-time-updates/) | Pushing updates to clients (polling, SSE, WebSockets) |
| [`long-running-tasks/`](./long-running-tasks/) | Moving slow work off the request path |
| [`multi-step-processes/`](./multi-step-processes/) | Coordinating multi-step flows across services (sagas) |
| [`large-blobs/`](./large-blobs/) | Uploading / serving large files |
| [`resilience/`](./resilience/) | Retries, circuit breakers, bulkheads, graceful degradation |
| [`idempotency/`](./idempotency/) | Making operations safe to retry |
| [`outbox-and-cdc/`](./outbox-and-cdc/) | Reliably publishing events from an OLTP database |
| [`rate-limiting-and-throttling/`](./rate-limiting-and-throttling/) | Controlling request rates at the edge and between services |

Every lab follows the same skeleton: `README.md`, `references/designgurus.md`,
`CHANGELOG.md`, plus the existing `notebooks/`, `docker-compose.yml` etc.
where present.

See also:
- [`../docs/restructure-proposal.md`](../docs/restructure-proposal.md) — overall repo structure
- [`../docs/content-map.md`](../docs/content-map.md) — lesson → lab mapping
