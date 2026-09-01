# 🏗️ System Design Labs

> **Learn system design by running real code.** Every lab is a self-contained
> sandbox with Docker-based infrastructure, Jupyter notebooks, and a
> **bad → better → best** teaching progression so you can *see why* the naive
> solution breaks before learning the production one.

[![Validate labs](https://github.com/ShonP/system-design-patterns/actions/workflows/validate-labs.yml/badge.svg)](https://github.com/ShonP/system-design-patterns/actions/workflows/validate-labs.yml)
![Labs](https://img.shields.io/badge/labs-160-blue)
![Notebooks](https://img.shields.io/badge/notebooks-529-orange)
![Categories](https://img.shields.io/badge/categories-9-green)
![Security Certs](https://img.shields.io/badge/cert%20tracks-4-red)
![Verified](https://img.shields.io/badge/labs%20verified-160%2F160-brightgreen)
![License](https://img.shields.io/badge/license-MIT-lightgrey)
![Stack](https://img.shields.io/badge/stack-Python%20%7C%20Docker%20%7C%20uv-purple)

This repo is **educational, not production-grade**. The code is intentionally
simple, well-commented, and optimized for learning — not performance or
hardening. Use it to experiment, break things, and build intuition.

---

## 📚 Table of Contents

1. [What's Inside](#-whats-inside)
2. [Getting Started](#-getting-started)
3. [Learning Roadmap](#-learning-roadmap-8-weeks)
4. [Full Lab Index](#-full-lab-index)
5. [How Each Lab Works](#-how-each-lab-works)
6. [Verifying the Labs](#-verifying-the-labs)
7. [Contributing](#-contributing)
8. [License](#-license)

---

## 🎯 What's Inside

| # | Category | Labs | Notebooks | What you'll learn |
|---|----------|-----:|----------:|-------------------|
| 01 | [Foundations](01-foundations/) | 16 | 62 | Core building blocks: caching, sharding, replication, load balancing, CAP, consistent hashing, IDs, observability, messaging basics, CDN, DNS, auth |
| 02 | [Distributed Primitives](02-distributed-primitives/) | 14 | 41 | Low-level mechanics: WAL, gossip, vector clocks, quorum, merkle trees, heartbeats, leases, hinted handoff, read repair, fencing |
| 03 | [Technologies](03-technologies/) | 11 + 6 refs | 60 | Deep dives: Postgres, Redis, Kafka, ZooKeeper, Cassandra, DynamoDB, Elasticsearch, vector/time-series DBs, Temporal + reference papers (GFS, HDFS, Bigtable, Dynamo, Chubby, S3) |
| 04 | [Patterns](04-patterns/) | 11 | 62 | Scaling & reliability: read/write scaling, contention, real-time, large blobs, rate limiting, resilience, idempotency, outbox/CDC, sagas |
| 05 | [Microservices](05-microservices/) | 12 | 39 | Service patterns: API gateway, BFF, service discovery, sidecar, circuit breaker, bulkhead, retry, saga, CQRS, EDA, strangler, config externalization |
| 06 | [System Designs](06-system-designs/) | 47 | 156 | End-to-end: Bitly, Uber, WhatsApp, Instagram, YouTube, Dropbox, Netflix, Discord, Tinder, Stock Exchange, Payment, Ticketmaster, +35 more |
| 07 | [Object-Oriented Design](07-object-oriented-design/) | 18 | 43 | Classic LLD/OOD interview problems: parking lot, elevator, chess, library, ATM, hotel, airline, +more |
| 08 | [Enterprise](08-enterprise/) | 5 | 21 | Process patterns: BCDR, GDPR paired regions, privacy review, security review, Azure auth |
| 09 | [Security](09-security/) | 10 | — | Hands-on AppSec labs driven by shell scripts (not notebooks): vulnerability scanning, secrets detection, SAST, container & Kubernetes security, OWASP web attacks, IaC scanning, incident response, network security, secure SDLC |
| — | [Security Certifications](security-certs/) | 4 tracks · 15 modules | 42 | Azure study labs: SC-900, SC-100, SC-200, AZ-500 |
| | **Total** | **159** | **526** | |

> Notebook counts are exact. `09-security/` is script-driven and has no
> notebooks. Some labs in
> `03-technologies/reference-systems/` and a few in `06-system-designs/`
> (e.g. `chatgpt/`) are currently documentation-only.

---

## 🚀 Getting Started

### Prerequisites

| Tool | Why | Install |
|------|-----|---------|
| **Python 3.10+** | Notebooks use modern typing / pattern matching | [python.org](https://www.python.org/downloads/) |
| **Docker + Compose** | Every lab ships real infra (Postgres, Redis, Kafka, …) | [Docker Desktop](https://www.docker.com/products/docker-desktop/) |
| **[uv](https://github.com/astral-sh/uv)** | Fast, reproducible Python env per lab (recommended) | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| **VS Code** (optional) | Best notebook experience; pick the per-lab `.venv` kernel | [code.visualstudio.com](https://code.visualstudio.com/) |

### Quick Start — your first lab in 3 minutes

```bash
# 1. Clone
git clone https://github.com/ShonP/system-design-patterns.git
cd system-design-patterns

# 2. Pick a lab (caching is a great first one)
cd 01-foundations/caching

# 3. Start the infrastructure (Redis + RedisInsight)
docker compose up -d

# 4. Install dependencies into a local .venv
uv sync

# 5. Open notebooks
#    In VS Code: open the folder, click the kernel picker (top-right of
#    any notebook), and select `.venv (Python 3.1x)`. If it doesn't appear,
#    Cmd/Ctrl+Shift+P → "Reload Window" and try again.
#    Or launch classic Jupyter:
uv run jupyter notebook notebooks/

# 6. When you're done, clean up
docker compose down -v
```

### Web UIs you'll use

Most labs expose a GUI on `localhost` so you can *watch* what your code is
doing (not just read about it):

| UI | What it shows | Typical port |
|---|---|---|
| Adminer / pgAdmin | Postgres tables, query plans | 8080 / 5050 |
| RedisInsight | Redis keys, streams, pub/sub | 5540 |
| Kibana | Elasticsearch indices & queries | 5601 |
| kafka-ui | Kafka topics, partitions, lag | 8080 |
| Temporal UI | Workflow executions & history | 8080 |
| Grafana | Metrics dashboards | 3000 |
| MinIO Console | S3-compatible object storage | 9001 |

---

## 🗺️ Learning Roadmap (~8 weeks)

If you're new, don't try to run everything. Here's a suggested path. Each week
is 3–5 labs at ~1–2 hours each.

### Week 1–2 · Foundations

Build intuition for the pieces that show up in *every* design.

1. [`01-foundations/numbers-to-know`](01-foundations/numbers-to-know/) — latency & throughput gut-feel
2. [`01-foundations/caching`](01-foundations/caching/) — cache-aside, write-through, stampede
3. [`01-foundations/sharding`](01-foundations/sharding/) — hash vs range vs consistent
4. [`01-foundations/replication`](01-foundations/replication/) — leader/follower, lag, failover
5. [`01-foundations/load-balancing`](01-foundations/load-balancing/) — L4 vs L7, round-robin vs least-conn
6. [`01-foundations/consistent-hashing`](01-foundations/consistent-hashing/) — modulo → ring → vnodes
7. [`01-foundations/cap-theorem`](01-foundations/cap-theorem/) — CP vs AP in practice
8. [`01-foundations/data-modeling`](01-foundations/data-modeling/) — relational, NoSQL, evolution
9. [`01-foundations/networking-essentials`](01-foundations/networking-essentials/) — DNS, TCP, HTTP/2, TLS
10. [`01-foundations/id-generation`](01-foundations/id-generation/), [`cdn/`](01-foundations/cdn/), [`observability/`](01-foundations/observability/), [`messaging-basics/`](01-foundations/messaging-basics/), [`bloom-filters/`](01-foundations/bloom-filters/), [`api-design/`](01-foundations/api-design/), [`authentication-authorization/`](01-foundations/authentication-authorization/)

### Week 3 · Distributed Primitives

The *how* behind replication, consensus, and failure detection.

- [`write-ahead-log`](02-distributed-primitives/write-ahead-log/)
- [`segmented-log`](02-distributed-primitives/segmented-log/)
- [`heartbeat`](02-distributed-primitives/heartbeat/), [`phi-accrual-failure-detection`](02-distributed-primitives/phi-accrual-failure-detection/)
- [`gossip-protocol`](02-distributed-primitives/gossip-protocol/)
- [`quorum`](02-distributed-primitives/quorum/), [`read-repair`](02-distributed-primitives/read-repair/), [`hinted-handoff`](02-distributed-primitives/hinted-handoff/)
- [`vector-clocks`](02-distributed-primitives/vector-clocks/), [`merkle-trees`](02-distributed-primitives/merkle-trees/)
- [`lease`](02-distributed-primitives/lease/), [`split-brain-and-fencing`](02-distributed-primitives/split-brain-and-fencing/)
- [`checksum`](02-distributed-primitives/checksum/), [`high-water-mark`](02-distributed-primitives/high-water-mark/)

### Week 4 · Technologies

Go deep on the tools you'll actually use.

1. [`databases/postgres`](03-technologies/databases/postgres/) — indexing bad→best, MVCC, replication
2. [`databases/redis`](03-technologies/databases/redis/) — data structures, pub/sub, streams, cluster
3. [`messaging/kafka`](03-technologies/messaging/kafka/) — partitions, exactly-once, Streams
4. [`coordination/zookeeper`](03-technologies/coordination/zookeeper/) — locks, leader election, watches
5. [`databases/cassandra`](03-technologies/databases/cassandra/), [`dynamodb`](03-technologies/databases/dynamodb/), [`elasticsearch`](03-technologies/databases/elasticsearch/)
6. [`databases/vector-databases`](03-technologies/databases/vector-databases/), [`time-series-databases`](03-technologies/databases/time-series-databases/)
7. [`workflow-engines/temporal`](03-technologies/workflow-engines/temporal/) — durable workflows
8. [`container-orchestration/kubernetes`](03-technologies/container-orchestration/kubernetes/) — pods → services → Helm → GitOps → mesh (**needs a local cluster**: minikube, kubectl, helm)

### Week 5 · Scaling & Reliability Patterns

Recurring problems and the menu of solutions.

- [`scaling-reads`](04-patterns/scaling-reads/), [`scaling-writes`](04-patterns/scaling-writes/)
- [`dealing-with-contention`](04-patterns/dealing-with-contention/)
- [`real-time-updates`](04-patterns/real-time-updates/) — polling → SSE → WebSockets → pub/sub
- [`long-running-tasks`](04-patterns/long-running-tasks/), [`multi-step-processes`](04-patterns/multi-step-processes/)
- [`large-blobs`](04-patterns/large-blobs/), [`rate-limiting-and-throttling`](04-patterns/rate-limiting-and-throttling/)
- [`idempotency`](04-patterns/idempotency/), [`resilience`](04-patterns/resilience/), [`outbox-and-cdc`](04-patterns/outbox-and-cdc/)

### Week 6 · Microservices Patterns

How services talk, degrade, and evolve.

- [`api-gateway`](05-microservices/api-gateway/), [`bff`](05-microservices/bff/), [`service-discovery`](05-microservices/service-discovery/)
- [`circuit-breaker`](05-microservices/circuit-breaker/), [`bulkhead`](05-microservices/bulkhead/), [`retry`](05-microservices/retry/)
- [`saga`](05-microservices/saga/), [`cqrs`](05-microservices/cqrs/), [`event-driven-architecture`](05-microservices/event-driven-architecture/)
- [`sidecar`](05-microservices/sidecar/), [`strangler`](05-microservices/strangler/), [`configuration-externalization`](05-microservices/configuration-externalization/)

### Week 7–8 · System Design Problems

Start small, build up. Each design reuses pieces from weeks 1–6.

**Warm-ups (pick 2–3):**
[`bitly`](06-system-designs/bitly/) ·
[`rate-limiter`](06-system-designs/rate-limiter/) ·
[`top-k`](06-system-designs/top-k/) ·
[`typeahead-autocomplete`](06-system-designs/typeahead-autocomplete/) ·
[`key-value-store`](06-system-designs/key-value-store/)

**Intermediate (pick 3–4):**
[`uber`](06-system-designs/uber/) ·
[`web-crawler`](06-system-designs/web-crawler/) ·
[`dropbox`](06-system-designs/dropbox/) ·
[`instagram`](06-system-designs/instagram/) ·
[`ticketmaster`](06-system-designs/ticketmaster/) ·
[`yelp`](06-system-designs/yelp/) ·
[`payment-system`](06-system-designs/payment-system/)

**Advanced (pick 2–3):**
[`netflix`](06-system-designs/netflix/) ·
[`youtube`](06-system-designs/youtube/) ·
[`whatsapp`](06-system-designs/whatsapp/) ·
[`discord`](06-system-designs/discord/) ·
[`google-docs`](06-system-designs/google-docs/) ·
[`stock-exchange`](06-system-designs/stock-exchange/)

### Optional tracks

- **Object-Oriented Design** → [`07-object-oriented-design/`](07-object-oriented-design/) — LLD interview prep
- **Enterprise / compliance** → [`08-enterprise/`](08-enterprise/) — privacy, BCDR, paired regions
- **Application security** → [`09-security/`](09-security/) — scanner-driven labs; run `./scripts/*.sh`, no Jupyter needed
- **Azure security certs** → [`security-certs/`](security-certs/) — SC-900 → SC-200 → AZ-500 → SC-100

---

## 📋 Full Lab Index

### 01 Foundations — core building blocks

| Lab | Notebooks | One-liner |
|---|---:|---|
| [`api-design`](01-foundations/api-design/) | 4 | REST principles, pagination, rate limiting, versioning |
| [`authentication-authorization`](01-foundations/authentication-authorization/) | 3 | Sessions, JWT, OAuth2, RBAC vs ABAC |
| [`bloom-filters`](01-foundations/bloom-filters/) | 4 | Probabilistic set membership |
| [`caching`](01-foundations/caching/) | 6 | Cache-aside, write-through, invalidation, TTL, stampede |
| [`cap-theorem`](01-foundations/cap-theorem/) | 3 | Consistency vs availability vs partitions |
| [`cdn`](01-foundations/cdn/) | 4 | Edge caching, origin shield, cache keys |
| [`consistent-hashing`](01-foundations/consistent-hashing/) | 4 | Modulo → hash ring → virtual nodes |
| [`data-modeling`](01-foundations/data-modeling/) | 5 | Relational, denormalization, NoSQL, schema evolution |
| [`id-generation`](01-foundations/id-generation/) | 4 | UUIDs, snowflake, ULID, collisions |
| [`load-balancing`](01-foundations/load-balancing/) | 4 | L4 vs L7, algorithms, health checks |
| [`messaging-basics`](01-foundations/messaging-basics/) | 3 | Queues, topics, delivery semantics |
| [`networking-essentials`](01-foundations/networking-essentials/) | 4 | DNS, TCP/UDP, HTTP/2, TLS |
| [`numbers-to-know`](01-foundations/numbers-to-know/) | 3 | Latency ladder, BOE estimation |
| [`observability`](01-foundations/observability/) | 4 | Logs, metrics, traces, SLOs |
| [`replication`](01-foundations/replication/) | 3 | Leader/follower, multi-leader, lag |
| [`sharding`](01-foundations/sharding/) | 4 | Hash, range, consistent, rebalancing |

### 02 Distributed Primitives — low-level mechanics

| Lab | Notebooks | One-liner |
|---|---:|---|
| [`checksum`](02-distributed-primitives/checksum/) | 3 | Integrity detection (CRC vs cryptographic) |
| [`gossip-protocol`](02-distributed-primitives/gossip-protocol/) | 2 | Epidemic membership / state dissemination |
| [`heartbeat`](02-distributed-primitives/heartbeat/) | 3 | Liveness signals between nodes |
| [`high-water-mark`](02-distributed-primitives/high-water-mark/) | 3 | Last durably replicated offset |
| [`hinted-handoff`](02-distributed-primitives/hinted-handoff/) | 3 | Writes survive brief node outages |
| [`lease`](02-distributed-primitives/lease/) | 3 | Time-bounded ownership / leader election |
| [`merkle-trees`](02-distributed-primitives/merkle-trees/) | 3 | Efficient replica reconciliation |
| [`phi-accrual-failure-detection`](02-distributed-primitives/phi-accrual-failure-detection/) | 3 | Adaptive failure detection |
| [`quorum`](02-distributed-primitives/quorum/) | 3 | Majority-based reads/writes (N, R, W) |
| [`read-repair`](02-distributed-primitives/read-repair/) | 3 | Reconcile stale replicas on reads |
| [`segmented-log`](02-distributed-primitives/segmented-log/) | 3 | Log split into indexed segments |
| [`split-brain-and-fencing`](02-distributed-primitives/split-brain-and-fencing/) | 3 | Two-leader scenarios & fencing tokens |
| [`vector-clocks`](02-distributed-primitives/vector-clocks/) | 2 | Causality and conflict detection |
| [`write-ahead-log`](02-distributed-primitives/write-ahead-log/) | 4 | Append-only log for crash-safe state |

### 03 Technologies — deep dives

**Databases**

| Lab | Notebooks | Focus |
|---|---:|---|
| [`databases/cassandra`](03-technologies/databases/cassandra/) | 5 | Wide-column, tunable consistency, gossip |
| [`databases/dynamodb`](03-technologies/databases/dynamodb/) | 5 | Partition/sort keys, GSI/LSI, single-table |
| [`databases/elasticsearch`](03-technologies/databases/elasticsearch/) | 4 | Full-text, analyzers, aggregations |
| [`databases/postgres`](03-technologies/databases/postgres/) | 4 | Indexing, MVCC, WAL, replication |
| [`databases/redis`](03-technologies/databases/redis/) | 5 | Data structures, streams, pub/sub, cluster |
| [`databases/time-series-databases`](03-technologies/databases/time-series-databases/) | 3 | TimescaleDB, aggregations, retention |
| [`databases/vector-databases`](03-technologies/databases/vector-databases/) | 4 | pgvector, linear → IVFFlat → HNSW |

**Messaging · Coordination · Workflow**

| Lab | Notebooks | Focus |
|---|---:|---|
| [`messaging/kafka`](03-technologies/messaging/kafka/) | 5 | Producers/consumers, partitions, exactly-once, Streams |
| [`coordination/zookeeper`](03-technologies/coordination/zookeeper/) | 5 | Locks, leader election, config, discovery, watches |
| [`workflow-engines/temporal`](03-technologies/workflow-engines/temporal/) | 10 | Durable workflows, sagas, signals, child workflows, versioning, AI agents, production deployment |

**Container orchestration · Actor runtimes**

| Lab | Notebooks | Focus |
|---|---:|---|
| [`container-orchestration/kubernetes`](03-technologies/container-orchestration/kubernetes/) | 10 | Cluster setup, pods/deployments, services & networking, Helm/Kustomize, observability, RBAC, GitOps with ArgoCD, service mesh, storage & secrets, production patterns. **Needs a real cluster** — the notebooks preflight-check for `minikube`/`kubectl`/`helm` and a reachable API server. |
| [`workflow-engines/orleans`](03-technologies/workflow-engines/orleans/) | — | Microsoft Orleans virtual actors. A **.NET** lab: 7 exercises under `labs/` run with `dotnet run`, not Jupyter — grains, state, timers/reminders, streams, AI agent grains, monitoring. |

**[Reference systems](03-technologies/reference-systems/) (canonical papers, docs-only)**

Paper guides rather than runnable labs — each covers the design, the trade-offs it
made and what it cost, and links to the labs here where those ideas run as code.

| Lab | Paper |
|---|---|
| [`reference-systems/gfs`](03-technologies/reference-systems/gfs/) | Google File System |
| [`reference-systems/hdfs`](03-technologies/reference-systems/hdfs/) | Hadoop Distributed File System |
| [`reference-systems/bigtable`](03-technologies/reference-systems/bigtable/) | Google Bigtable |
| [`reference-systems/dynamo`](03-technologies/reference-systems/dynamo/) | Amazon Dynamo |
| [`reference-systems/chubby`](03-technologies/reference-systems/chubby/) | Google Chubby lock service |
| [`reference-systems/s3`](03-technologies/reference-systems/s3/) | Amazon S3 |

### 04 Patterns — scaling & reliability

| Lab | Notebooks | Problem |
|---|---:|---|
| [`dealing-with-contention`](04-patterns/dealing-with-contention/) | 5 | Concurrent updates: locks, optimistic, CRDTs |
| [`idempotency`](04-patterns/idempotency/) | 4 | Making operations safe to retry |
| [`large-blobs`](04-patterns/large-blobs/) | 6 | Chunked uploads, presigned URLs, CDN |
| [`long-running-tasks`](04-patterns/long-running-tasks/) | 6 | Queues, workers, DLQ, backpressure |
| [`multi-step-processes`](04-patterns/multi-step-processes/) | 6 | Workflows, sagas, Temporal |
| [`outbox-and-cdc`](04-patterns/outbox-and-cdc/) | 4 | Reliably publishing events from OLTP |
| [`rate-limiting-and-throttling`](04-patterns/rate-limiting-and-throttling/) | 6 | Edge & service-to-service rate control |
| [`real-time-updates`](04-patterns/real-time-updates/) | 8 | Polling → SSE → WebSockets → pub/sub |
| [`resilience`](04-patterns/resilience/) | 5 | Retries, circuit breakers, bulkheads |
| [`scaling-reads`](04-patterns/scaling-reads/) | 6 | Caching, read replicas, materialized views |
| [`scaling-writes`](04-patterns/scaling-writes/) | 6 | Sharding, partitioning, write buffering |

### 05 Microservices — service patterns

| Lab | Notebooks | Pattern |
|---|---:|---|
| [`api-gateway`](05-microservices/api-gateway/) | 4 | Edge service fronting a set of microservices |
| [`bff`](05-microservices/bff/) | 3 | Backend-for-Frontend per client type |
| [`bulkhead`](05-microservices/bulkhead/) | 2 | Isolate resource pools to contain failures |
| [`circuit-breaker`](05-microservices/circuit-breaker/) | 3 | Fail fast when a downstream is unhealthy |
| [`configuration-externalization`](05-microservices/configuration-externalization/) | 4 | Keep config out of the binary |
| [`cqrs`](05-microservices/cqrs/) | 3 | Split read and write models |
| [`event-driven-architecture`](05-microservices/event-driven-architecture/) | 4 | Services communicating via events |
| [`retry`](05-microservices/retry/) | 3 | Safely retrying transient failures |
| [`saga`](05-microservices/saga/) | 4 | Multi-service transactions without 2PC |
| [`service-discovery`](05-microservices/service-discovery/) | 3 | Finding healthy instances at runtime |
| [`sidecar`](05-microservices/sidecar/) | 3 | Out-of-process helper bundled with a service |
| [`strangler`](05-microservices/strangler/) | 3 | Incrementally replacing a legacy system |

### 06 System Designs — end-to-end problems

| Lab | Notebooks | Focus |
|---|---:|---|
| [`ad-click-aggregator`](06-system-designs/ad-click-aggregator/) | 3 | Click ingestion, real-time aggregation, dedup |
| [`airbnb`](06-system-designs/airbnb/) | 3 | Two-sided marketplace: listings, bookings |
| [`amazon-lambda`](06-system-designs/amazon-lambda/) | 3 | FaaS: cold starts, scheduling |
| [`bitly`](06-system-designs/bitly/) | 3 | URL shortener with click analytics |
| [`code-deployment`](06-system-designs/code-deployment/) | 3 | CI/CD and deployment orchestration |
| [`collaborative-whiteboard`](06-system-designs/collaborative-whiteboard/) | 3 | Miro-style real-time canvas |
| [`discord`](06-system-designs/discord/) | 3 | Real-time chat, voice, presence |
| [`distributed-cache`](06-system-designs/distributed-cache/) | 4 | Partitioning, coherence, consistent hashing |
| [`distributed-lock-manager`](06-system-designs/distributed-lock-manager/) | 3 | Chubby-style distributed locks |
| [`dropbox`](06-system-designs/dropbox/) | 4 | File sync, dedup, sharing |
| [`fb-live-comments`](06-system-designs/fb-live-comments/) | 3 | Live comment streaming & ordering |
| [`fb-news-feed`](06-system-designs/fb-news-feed/) | 4 | Fan-out, ranking, social graph |
| [`fb-post-search`](06-system-designs/fb-post-search/) | 3 | Full-text indexing, typeahead |
| [`flash-sale`](06-system-designs/flash-sale/) | 3 | Ecommerce flash-sale bursts |
| [`gmail`](06-system-designs/gmail/) | 3 | Webmail at scale |
| [`google-calendar`](06-system-designs/google-calendar/) | 3 | Calendaring and invitations |
| [`google-docs`](06-system-designs/google-docs/) | 4 | OT, CRDTs, real-time collaboration |
| [`google-search`](06-system-designs/google-search/) | 3 | Web-scale search |
| [`gopuff`](06-system-designs/gopuff/) | 3 | On-demand delivery logistics |
| [`instagram`](06-system-designs/instagram/) | 4 | Photo pipeline, feed, stories, explore |
| [`job-scheduler`](06-system-designs/job-scheduler/) | 3 | Distributed job queue, DLQ |
| [`key-value-store`](06-system-designs/key-value-store/) | 3 | DynamoDB-style KV store |
| [`leetcode`](06-system-designs/leetcode/) | 3 | Sandboxed execution, leaderboards |
| [`linkedin-connections`](06-system-designs/linkedin-connections/) | 3 | PYMK graph |
| [`metrics-monitoring`](06-system-designs/metrics-monitoring/) | 3 | Prometheus, alerting, Grafana |
| [`netflix`](06-system-designs/netflix/) | 3 | Streaming + recommendations |
| [`news-aggregator`](06-system-designs/news-aggregator/) | 3 | Crawling, dedup, personalized feeds |
| [`notification-system`](06-system-designs/notification-system/) | 4 | Multi-channel fan-out |
| [`online-auction`](06-system-designs/online-auction/) | 4 | Bid processing, fairness |
| [`payment-system`](06-system-designs/payment-system/) | 4 | Pipeline, idempotency, ledger, fraud |
| [`rate-limiter`](06-system-designs/rate-limiter/) | 4 | Token bucket, sliding window, distributed limiting with Redis, limiting at the gateway |
| [`reddit`](06-system-designs/reddit/) | 3 | Forum/feed platform |
| [`reminder-alert`](06-system-designs/reminder-alert/) | 3 | Scheduled reminders at scale |
| [`robinhood`](06-system-designs/robinhood/) | 3 | Brokerage backend, market data |
| [`s3`](06-system-designs/s3/) | 3 | Object storage |
| [`shopping-cart`](06-system-designs/shopping-cart/) | 3 | Amazon-style cart |
| [`stock-exchange`](06-system-designs/stock-exchange/) | 3 | Order-matching engine |
| [`strava`](06-system-designs/strava/) | 3 | GPS tracking, leaderboards |
| [`ticketmaster`](06-system-designs/ticketmaster/) | 4 | Seat locking, flash sales, reservations |
| [`tinder`](06-system-designs/tinder/) | 3 | Geolocation matching, swipes |
| [`top-k`](06-system-designs/top-k/) | 3 | Count-min sketch, heap, distributed MR |
| [`typeahead-autocomplete`](06-system-designs/typeahead-autocomplete/) | 4 | Search-as-you-type suggestions |
| [`uber`](06-system-designs/uber/) | 4 | Geospatial matching, surge, driver tracking |
| [`web-crawler`](06-system-designs/web-crawler/) | 4 | Politeness, fault tolerance, efficiency |
| [`whatsapp`](06-system-designs/whatsapp/) | 4 | Delivery, receipts, groups, E2EE |
| [`yelp`](06-system-designs/yelp/) | 3 | Geospatial search, ranking |
| [`youtube`](06-system-designs/youtube/) | 4 | Upload, processing, streaming, resumable |

Docs-only (no notebooks yet): `chatgpt/`.

### 07 Object-Oriented Design — LLD interview problems

| Lab | Notebooks | Problem |
|---|---:|---|
| [`uml-basics`](07-object-oriented-design/uml-basics/) | 3 | UML: class, sequence, activity, use-case |
| [`oo-analysis-and-design`](07-object-oriented-design/oo-analysis-and-design/) | 2 | OOA/OOD process and SOLID |
| [`airline-management`](07-object-oriented-design/airline-management/) | 2 | Airline management |
| [`amazon-shopping`](07-object-oriented-design/amazon-shopping/) | 2 | Amazon-style online store |
| [`atm`](07-object-oriented-design/atm/) | 2 | ATM |
| [`blackjack`](07-object-oriented-design/blackjack/) | 3 | Blackjack and a deck of cards |
| [`car-rental`](07-object-oriented-design/car-rental/) | 2 | Car rental |
| [`chess`](07-object-oriented-design/chess/) | 2 | Chess |
| [`cricinfo`](07-object-oriented-design/cricinfo/) | 2 | Cricket information service |
| [`facebook`](07-object-oriented-design/facebook/) | 2 | Facebook-style social network |
| [`hotel-management`](07-object-oriented-design/hotel-management/) | 3 | Hotel management |
| [`library-management`](07-object-oriented-design/library-management/) | 2 | Library management |
| [`linkedin`](07-object-oriented-design/linkedin/) | 2 | LinkedIn |
| [`movie-ticket-booking`](07-object-oriented-design/movie-ticket-booking/) | 2 | Movie-ticket booking |
| [`online-stock-brokerage`](07-object-oriented-design/online-stock-brokerage/) | 3 | Online stock brokerage |
| [`parking-lot`](07-object-oriented-design/parking-lot/) | 3 | Parking-lot system |
| [`restaurant`](07-object-oriented-design/restaurant/) | 3 | Restaurant management |
| [`stack-overflow`](07-object-oriented-design/stack-overflow/) | 3 | Stack Overflow |

### 08 Enterprise — process & compliance

| Lab | Notebooks | Focus |
|---|---:|---|
| [`azure-authentication`](08-enterprise/azure-authentication/) | 5 | Entra ID, managed identities, OAuth flows |
| [`bcdr`](08-enterprise/bcdr/) | 4 | RPO/RTO, failover, backups, DR drills |
| [`gdpr-paired-regions`](08-enterprise/gdpr-paired-regions/) | 4 | Data residency, replication, right-to-erasure |
| [`privacy-review`](08-enterprise/privacy-review/) | 4 | Data classification, PIA, anonymization |
| [`security-review`](08-enterprise/security-review/) | 4 | STRIDE, OWASP Top 10, SDL, secrets |

### 🔐 Security Certifications

Azure security cert study labs (kept separate from system-design content).

| Track | Modules | Path |
|---|---:|---|
| SC-900 (Fundamentals) | 4 | [`security-certs/sc-900/`](security-certs/sc-900/) |
| SC-200 (Security Operations) | 3 | [`security-certs/sc-200/`](security-certs/sc-200/) |
| AZ-500 (Security Engineer) | 4 | [`security-certs/az-500/`](security-certs/az-500/) |
| SC-100 (Cybersecurity Architect) | 4 | [`security-certs/sc-100/`](security-certs/sc-100/) |

---

## 🧪 How Each Lab Works

Every lab follows the same skeleton so once you've learned one, you've learned
all of them:

```
<lab-name>/
├── README.md              ← problem statement, architecture, learning goals
├── docker-compose.yml     ← Postgres / Redis / Kafka / Temporal / … (if needed)
├── pyproject.toml         ← Python deps, managed with uv
├── uv.lock                ← locked versions for reproducibility
├── .venv/                 ← created by `uv sync` (gitignored)
├── db/                    ← optional SQL init scripts
├── app/                   ← optional FastAPI service(s)
├── references/            ← links to source material (Design Gurus, papers)
├── CHANGELOG.md           ← what's been added over time
└── notebooks/
    ├── 00_setup.ipynb     ← env check + kernel instructions
    ├── 01_bad.ipynb       ← the naive approach, and how it breaks
    ├── 02_better.ipynb    ← a first real improvement
    ├── 03_best.ipynb      ← the production-grade pattern
    └── 04_*.ipynb         ← optional deeper dives
```

### The bad → better → best progression

Every concept is taught in three stages so you **feel** the tradeoffs instead
of memorizing them:

1. **Bad** — the obvious first attempt. You run it, watch it fall over under
   load / failure / contention, and understand *why* a better solution exists.
2. **Better** — a meaningful improvement that solves the headline problem but
   still has edge cases.
3. **Best** — the production pattern. You see what it costs (code, infra,
   operational burden) and understand when it's worth paying.

Examples:
- **Consistent hashing** → `modulo % N` → `hash ring` → `hash ring + virtual nodes`
- **Postgres indexing** → full table scan → single-column B-tree → composite / partial / covering
- **Rate limiting** → in-memory counter → Redis token bucket → distributed sliding window
- **Vector search** → linear scan → IVFFlat → HNSW

### Docker infra

Every lab that needs a database or broker ships a `docker-compose.yml` that
brings it up locally with sensible defaults and — importantly — a **web UI**
on `localhost` so you can inspect what your code is doing.

### Per-lab virtualenv

Each lab has its own `.venv` managed by [uv](https://docs.astral.sh/uv/) so
dependencies don't conflict across labs. Inside the lab:

```bash
uv sync                         # create .venv and install deps
uv run jupyter notebook ...     # run a command in the .venv
uv run pytest                   # if tests exist
```

In VS Code, open the lab folder and pick `.venv` from the kernel picker in the
top-right of any notebook. If it doesn't show up, `Cmd/Ctrl+Shift+P` →
**Reload Window**.

---

## 🔧 Verifying the labs

The repo ships its own test harness in [`tools/`](tools/) — see
[`tools/README.md`](tools/README.md) for the details.

```bash
python3 tools/validate_labs.py              # static checks over every lab (seconds)
python3 tools/check_ports.py                # which labs would fail to start right now, and why
python3 tools/run_labs.py --all --no-docker # actually execute the labs that need no containers
python3 tools/run_labs.py 01-foundations/caching   # one lab, containers and all
```

`validate_labs.py` exits non-zero on any error, so it works as a CI gate.
If a stack refuses to start, run `check_ports.py` first — labs publish fixed host
ports and cannot run two at a time, so the usual cause is another lab you forgot
to tear down.

**Every lab has been executed against real infrastructure** — 160/160, including
the Kubernetes lab (which needs a cluster) and the shell-driven security labs.
The one thing worth knowing before you trust a green run:

> A lab that runs cleanly is not a lab that is correct. Every lab here executed
> without error before the correctness pass, and the review still found real
> defects in most of them — a top-K heap that evicted genuine heavy hitters, an
> operational-transform function that did not converge, a reconciler that marked
> orders filled with no ledger entry. Assertions were added throughout so a lab
> that stops reproducing its own lesson now fails loudly.

The findings, the failure patterns, and what remains open are in
[`docs/VERIFICATION-HANDOFF.md`](docs/VERIFICATION-HANDOFF.md). Per-lab state lives in
[`tools/qa-status.json`](tools/qa-status.json).

## 🤝 Contributing

Contributions are welcome! The repo follows a few conventions that keep the
labs consistent and beginner-friendly:

### Principles

1. **Beginner-first.** Explain like the reader has no prior knowledge. Prefer
   plain language and analogies over jargon.
2. **Minimal dependencies.** Use the simplest tool that demonstrates the
   concept. Python + Docker + one database is usually enough.
3. **Bad → better → best.** Every lab should let the reader *see* why the
   naive approach fails before meeting the production one.
4. **Runnable end-to-end.** Run everything yourself before opening a PR. If
   `docker compose up -d && uv sync && uv run jupyter nbconvert --execute
   notebooks/*.ipynb` doesn't work, neither does your lab.
5. **Add, don't replace.** New content on an existing topic should *extend*
   existing notebooks, not rewrite them.

### Adding a new lab

1. Pick the right home: foundations, primitive, technology deep dive,
   scaling pattern, microservices pattern, or end-to-end system design.
   See [`docs/restructure-proposal.md`](docs/restructure-proposal.md) §4 for
   the decision tree.
2. Copy an existing sibling lab as a template (e.g. copy
   `01-foundations/caching/` if you're adding a foundations lab).
3. Update: `README.md` (problem, architecture, learning goals),
   `docker-compose.yml` (only what you need), `pyproject.toml`,
   `notebooks/`, and `CHANGELOG.md`.
4. Verify:
   ```bash
   docker compose up -d
   uv sync
   uv run jupyter nbconvert --execute notebooks/*.ipynb
   docker compose down -v
   ```
5. Add a one-liner to the relevant category `README.md` and to this index.

### Content conventions

- Per-lab `.venv` (uv-managed). Don't commit `.venv/`.
- Notebooks are numbered (`01_`, `02_`, …) and include a setup cell at the
  top explaining how to pick the `.venv` kernel.
- Use [Pydantic](https://docs.pydantic.dev/) for validation and
  [FastAPI](https://fastapi.tiangolo.com/) for any HTTP services — the
  simplest widely-adopted pair.
- Use Adminer / pgAdmin / RedisInsight / Kibana / Grafana / Temporal UI /
  kafka-ui instead of writing custom dashboards.
- See [`docs/restructure-proposal.md`](docs/restructure-proposal.md) and
  [`docs/content-map.md`](docs/content-map.md) for the full rationale.

---

## 📝 License

MIT License — see [LICENSE](LICENSE). Use freely for learning and teaching.

## 🙏 Acknowledgments

Content inspired by [Hello Interview](https://www.hellointerview.com/) and
Design Gurus' *Grokking* system-design courses. The labs are the author's
own implementations; references to source material live in each lab's
`references/` directory.
