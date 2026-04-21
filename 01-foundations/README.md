# 01 Foundations

The core building blocks every backend engineer should know. Start here if
you're new — most of the patterns and system-design labs in this repo assume
you're comfortable with these topics.

Each lab follows the standard **bad → better → best** progression, ships with
Docker-based infrastructure where needed, and runs in Jupyter notebooks.

## Labs in this section

| Lab | Notebooks | What it covers |
|---|---:|---|
| [`api-design/`](./api-design/) | 4 | REST principles, pagination, rate limiting, versioning |
| [`authentication-authorization/`](./authentication-authorization/) | 3 | Sessions, JWT, OAuth2, RBAC vs ABAC |
| [`bloom-filters/`](./bloom-filters/) | 4 | Probabilistic set membership, false-positive tradeoffs |
| [`caching/`](./caching/) | 6 | Cache-aside, write-through, invalidation, TTL, stampede |
| [`cap-theorem/`](./cap-theorem/) | 3 | Consistency vs availability under partitions |
| [`cdn/`](./cdn/) | 4 | Edge caching, origin shield, cache keys |
| [`consistent-hashing/`](./consistent-hashing/) | 4 | `modulo % N` → hash ring → virtual nodes |
| [`data-modeling/`](./data-modeling/) | 4 | Relational, denormalization, NoSQL, schema evolution |
| [`id-generation/`](./id-generation/) | 4 | UUIDs, Snowflake, ULID, collision tradeoffs |
| [`load-balancing/`](./load-balancing/) | 4 | L4 vs L7, round-robin / least-conn, health checks |
| [`messaging-basics/`](./messaging-basics/) | 3 | Queues, topics, delivery semantics |
| [`networking-essentials/`](./networking-essentials/) | 4 | DNS, TCP/UDP, HTTP/2, TLS |
| [`numbers-to-know/`](./numbers-to-know/) | 3 | Latency ladder, throughput, back-of-envelope |
| [`observability/`](./observability/) | 4 | Logs, metrics, traces, SLOs |
| [`replication/`](./replication/) | 3 | Leader/follower, multi-leader, replication lag |
| [`sharding/`](./sharding/) | 4 | Hash, range, consistent, rebalancing |

## Suggested order

1. **`numbers-to-know`** — build gut-feel for latency and throughput
2. **`caching`** — the single most-used pattern in the repo
3. **`sharding`** → **`consistent-hashing`** — how data gets distributed
4. **`replication`** → **`cap-theorem`** — how data stays available
5. **`load-balancing`** → **`networking-essentials`** → **`cdn`** — how traffic gets to you
6. **`data-modeling`** → **`id-generation`** → **`bloom-filters`** — how you store it
7. **`api-design`** → **`authentication-authorization`** → **`messaging-basics`** → **`observability`** — the surface area

See also:
- [`../docs/restructure-proposal.md`](../docs/restructure-proposal.md) — overall repo structure
- [`../docs/content-map.md`](../docs/content-map.md) — lesson → lab mapping
