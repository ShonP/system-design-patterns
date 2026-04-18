# 🏗️ System Design Labs

**57 hands-on labs · 220 Jupyter notebooks · Real Docker infrastructure**

Learn system design by running real code. Each lab includes Docker-based infrastructure, Python notebooks with working examples, and follows a **bad → better → best** teaching pattern.

## 🎯 What's Inside

| Category | Labs | Notebooks | Description |
|----------|------|-----------|-------------|
| [01 Foundations](#-01-foundations) | 8 | 30 | Fundamental building blocks |
| [02 Distributed Primitives](#-02-distributed-primitives) | 0 | 0 | _(planned)_ Bloom filters, replication, leader election, … |
| [03 Technologies](#-03-technologies) | 10 | 40 | Technology-specific deep dives (databases, messaging, coordination, workflow engines) |
| [04 Patterns](#-04-patterns) | 7 | 42 | Cross-cutting scaling & reliability patterns |
| [05 Microservices](#-05-microservices) | 1 | 3 | Microservices patterns (API gateway, …) |
| [06 System Designs](#-06-system-designs) | 27 | 93 | End-to-end system design problems |
| [07 Object-Oriented Design](#-07-object-oriented-design) | 0 | 0 | _(planned)_ OOD / LLD problems |
| [08 Enterprise](#-08-enterprise) | 4 | 16 | Microsoft/enterprise-grade patterns |
| [Security Certifications](#-security-certifications) | 4 tracks | – | Azure security certification labs |
| **Total** | **57** | **220** | |

> **🚧 Restructure in progress.** The top-level folders were reorganized; the
> old `core-concepts/`, `deep-dives/`, `patterns/`, `enterprise-patterns/`,
> `system-designs/`, `security/`, and `scraper/` directories moved to new
> numbered homes. See [`docs/restructure-proposal.md`](docs/restructure-proposal.md)
> for the full rationale and plan.

## 🚀 Getting Started

### Prerequisites

- Python 3.10+
- Docker & Docker Compose
- [uv](https://github.com/astral-sh/uv) (recommended) or pip

### Quick Start

```bash
# Clone the repository
git clone https://github.com/ShonP/system-design-patterns.git
cd system-design-labs

# Pick a lab to explore
cd 01-foundations/caching

# Start the infrastructure
docker compose up -d

# Install dependencies
uv sync

# Open notebooks
jupyter notebook notebooks/
```

### Visualization Tools

Each lab includes web UIs for observing what's happening:

| Tool | Purpose | Common Port |
|------|---------|-------------|
| Adminer | PostgreSQL GUI | 8080 |
| RedisInsight | Redis GUI | 5540 |
| Kibana | Elasticsearch GUI | 5601 |
| Grafana | Metrics dashboards | 3000 |
| Temporal UI | Workflow visualization | 8080 |
| MinIO Console | Object storage GUI | 9001 |
| pgAdmin | Advanced PostgreSQL GUI | 5050 |
| kafka-ui | Kafka cluster GUI | 8080 |

---

## 📘 01 Foundations

Fundamental building blocks every engineer needs to know.

| Lab | Notebooks | Topics |
|-----|-----------|--------|
| [API Design](01-foundations/api-design/) | 4 | REST principles, pagination, rate limiting, versioning |
| [Caching](01-foundations/caching/) | 5 | Cache-aside, write-through, invalidation, TTL, stampede |
| [CAP Theorem](01-foundations/cap-theorem/) | 3 | Consistency vs availability, partition tolerance |
| [Consistent Hashing](01-foundations/consistent-hashing/) | 3 | Modulo → hash ring → virtual nodes (bad→better→best) |
| [Data Modeling](01-foundations/data-modeling/) | 4 | Relational, denormalization, NoSQL, schema evolution |
| [Networking Essentials](01-foundations/networking-essentials/) | 4 | DNS, load balancing, TCP/UDP, HTTP/2, TLS |
| [Numbers to Know](01-foundations/numbers-to-know/) | 3 | Latency benchmarks, throughput, back-of-envelope estimation |
| [Sharding](01-foundations/sharding/) | 4 | Hash-based, range-based, consistent hashing, rebalancing |

## 🧩 02 Distributed Primitives

_Planned._ Low-level building blocks of distributed systems (bloom filters,
replication, id-generation, leader election, consensus). See
[`docs/restructure-proposal.md`](docs/restructure-proposal.md) section 4.

## 🔬 03 Technologies

Technology-specific deep dives with real infrastructure.

### Databases

| Lab | Notebooks | Topics |
|-----|-----------|--------|
| [Cassandra](03-technologies/databases/cassandra/) | 4 | Partition keys, wide rows, consistency levels, compaction |
| [DynamoDB](03-technologies/databases/dynamodb/) | 4 | Partition/sort keys, GSI/LSI, single-table design, Streams |
| [Elasticsearch](03-technologies/databases/elasticsearch/) | 4 | Full-text search, analyzers, aggregations, scaling |
| [PostgreSQL](03-technologies/databases/postgres/) | 4 | Indexing (bad→best), query optimization, replication, partitioning |
| [Redis](03-technologies/databases/redis/) | 4 | Data structures, pub/sub, cache vs primary, cluster |
| [Time-Series Databases](03-technologies/databases/time-series-databases/) | 3 | TimescaleDB, windowed aggregations, retention policies |
| [Vector Databases](03-technologies/databases/vector-databases/) | 3 | pgvector, linear scan → IVFFlat → HNSW (bad→best) |

### Messaging

| Lab | Notebooks | Topics |
|-----|-----------|--------|
| [Kafka](03-technologies/messaging/kafka/) | 4 | Producers/consumers, partitioning, exactly-once, Streams |

### Coordination

| Lab | Notebooks | Topics |
|-----|-----------|--------|
| [ZooKeeper](03-technologies/coordination/zookeeper/) | 3 | Distributed locks, leader election, config management |

### Workflow Engines

| Lab | Notebooks | Topics |
|-----|-----------|--------|
| [Temporal](03-technologies/workflow-engines/temporal/) | 4 | Workflow engines, saga pattern, signals, versioning |

## 🔄 04 Patterns

Cross-cutting scaling & reliability patterns.

| Pattern | Notebooks | Topics |
|---------|-----------|--------|
| [Real-Time Updates](04-patterns/real-time-updates/) | 7 | Polling, SSE, WebSockets, pub/sub |
| [Dealing with Contention](04-patterns/dealing-with-contention/) | 5 | Locks, optimistic concurrency, CRDTs |
| [Scaling Reads](04-patterns/scaling-reads/) | 6 | Caching, read replicas, materialized views |
| [Scaling Writes](04-patterns/scaling-writes/) | 6 | Sharding, partitioning, write buffering |
| [Handling Large Blobs](04-patterns/large-blobs/) | 6 | Chunked uploads, presigned URLs, CDN |
| [Long Running Tasks](04-patterns/long-running-tasks/) | 6 | Queues, workers, DLQ, backpressure |
| [Multi-Step Processes](04-patterns/multi-step-processes/) | 6 | Workflows, sagas, Temporal |

## 🕸️ 05 Microservices

Microservices design patterns.

| Lab | Notebooks | Topics |
|-----|-----------|--------|
| [API Gateway](05-microservices/api-gateway/) | 3 | Routing, load balancing, rate limiting, auth (nginx) |

## 🏛️ 06 System Designs

Complete system design problems with hands-on implementations.

| Lab | Notebooks | Topics |
|-----|-----------|--------|
| [Ad Click Aggregator](06-system-designs/ad-click-aggregator/) | 3 | Click ingestion, real-time aggregation, deduplication |
| [Bitly (URL Shortener)](06-system-designs/bitly/) | 3 | URL encoding, redirect caching, analytics |
| [Distributed Cache](06-system-designs/distributed-cache/) | 3 | Cache partitioning, coherence, consistent hashing |
| [Distributed Rate Limiter](06-system-designs/distributed-rate-limiter/) | 3 | Token bucket, sliding window, distributed |
| [Dropbox (File Storage)](06-system-designs/dropbox/) | 4 | Chunked uploads, sync, deduplication, sharing |
| [FB Live Comments](06-system-designs/fb-live-comments/) | 3 | Real-time streaming, ordering, scaling |
| [FB News Feed](06-system-designs/fb-news-feed/) | 4 | Fan-out, ranking, social graph, feed caching |
| [FB Post Search](06-system-designs/fb-post-search/) | 3 | Full-text indexing, typeahead, search ranking |
| [Google Docs](06-system-designs/google-docs/) | 4 | OT, CRDTs, real-time collaboration, versioning |
| [Gopuff (Local Delivery)](06-system-designs/gopuff/) | 3 | Inventory, delivery routing, demand forecasting |
| [Instagram](06-system-designs/instagram/) | 4 | Photo pipeline, news feed, stories, explore |
| [Job Scheduler](06-system-designs/job-scheduler/) | 3 | Job queues, distributed execution, dead letter queues |
| [LeetCode](06-system-designs/leetcode/) | 3 | Code submission, sandboxed execution, leaderboards |
| [Metrics Monitoring](06-system-designs/metrics-monitoring/) | 3 | Prometheus, alerting, Grafana dashboards |
| [News Aggregator](06-system-designs/news-aggregator/) | 3 | RSS crawling, deduplication, personalized feeds |
| [Online Auction](06-system-designs/online-auction/) | 3 | Bid processing, auction lifecycle, real-time notifications |
| [Payment System](06-system-designs/payment-system/) | 4 | Processing pipeline, idempotency, ledger, fraud detection |
| [Rate Limiter](06-system-designs/rate-limiter/) | 4 | Token bucket, sliding window, distributed, API gateway |
| [Robinhood (Stock Trading)](06-system-designs/robinhood/) | 3 | Order matching, portfolio tracking, market data streaming |
| [Strava (Fitness Tracking)](06-system-designs/strava/) | 3 | GPS tracking, activity feed, segment leaderboards |
| [Ticketmaster](06-system-designs/ticketmaster/) | 4 | Seat locking, flash sales, reservation flow, scaling |
| [Tinder (Dating App)](06-system-designs/tinder/) | 3 | Geolocation matching, swipe system, notifications |
| [Top-K](06-system-designs/top-k/) | 3 | Count-min sketch, heap-based, distributed MapReduce |
| [Uber (Ride-Sharing)](06-system-designs/uber/) | 4 | Geospatial matching, driver tracking, surge pricing |
| [Web Crawler](06-system-designs/web-crawler/) | 4 | Basic crawler, fault tolerance, politeness, efficiency |
| [WhatsApp (Messaging)](06-system-designs/whatsapp/) | 4 | Message delivery, read receipts, groups, E2E encryption |
| [Yelp (Local Search)](06-system-designs/yelp/) | 3 | Geospatial search, reviews, search ranking |
| [YouTube (Video Streaming)](06-system-designs/youtube/) | 4 | Upload, streaming, processing, resumable uploads |

## 🧱 07 Object-Oriented Design

_Planned._ OOD / LLD problems (parking-lot, elevator, library, chess, …) from
the Grokking OOD course. See
[`docs/restructure-proposal.md`](docs/restructure-proposal.md).

## 🏢 08 Enterprise

Production patterns used at Microsoft and large enterprises.

| Lab | Notebooks | Topics |
|-----|-----------|--------|
| [Azure Authentication](08-enterprise/azure-authentication/) | – | Entra ID, managed identities, OAuth flows |
| [BCDR](08-enterprise/bcdr/) | 4 | RPO/RTO, replication failover, backup strategies, DR drills |
| [GDPR Paired Regions](08-enterprise/gdpr-paired-regions/) | 4 | Data residency, cross-region replication, right to erasure |
| [Privacy Review](08-enterprise/privacy-review/) | 4 | Data classification, PIA, anonymization, retention |
| [Security Review](08-enterprise/security-review/) | 4 | STRIDE, OWASP Top 10, secrets management, SDL |

> **Note:** Temporal workflows moved to
> [`03-technologies/workflow-engines/temporal/`](03-technologies/workflow-engines/temporal/).

## 🔐 Security Certifications

Azure security certification study labs (kept separate from system-design
content).

| Track | Path |
|---|---|
| SC-900 | [`security-certs/sc-900/`](security-certs/sc-900/) |
| SC-100 | [`security-certs/sc-100/`](security-certs/sc-100/) |
| SC-200 | [`security-certs/sc-200/`](security-certs/sc-200/) |
| AZ-500 | [`security-certs/az-500/`](security-certs/az-500/) |

---

## 🏛️ Repository Structure

```
system-design-labs/
├── docs/                          # Proposals, content map
├── 01-foundations/                # Fundamental building blocks
├── 02-distributed-primitives/     # (planned) Bloom filters, replication, …
├── 03-technologies/               # Technology deep dives
│   ├── databases/                 # postgres, cassandra, redis, …
│   ├── messaging/                 # kafka
│   ├── coordination/              # zookeeper
│   └── workflow-engines/          # temporal
├── 04-patterns/                   # Scaling & reliability patterns
├── 05-microservices/              # Microservices patterns (api-gateway, …)
├── 06-system-designs/             # End-to-end system designs
├── 07-object-oriented-design/     # (planned) OOD / LLD problems
├── 08-enterprise/                 # Enterprise / process patterns
├── security-certs/                # Azure security cert labs
└── tools/
    └── scraper/                   # Content scraper (dev tool)
```

Each lab follows the same structure:
- **README.md** — Overview and learning objectives
- **docker-compose.yml** — Infrastructure setup
- **pyproject.toml** — Python dependencies (managed with [uv](https://docs.astral.sh/uv/))
- **notebooks/** — Interactive Jupyter notebooks (numbered)
- **db/** (optional) — SQL initialization scripts

## 🎓 How to Learn

1. **Pick a topic** — Start with Core Concepts if new, or jump to a System Design
2. **Read the README** — Understand the problem and architecture
3. **Start infrastructure** — `docker compose up -d`
4. **Run notebooks in order** — Each builds on the previous
5. **Follow bad → better → best** — See why naive solutions fail before learning the right way
6. **Experiment** — Change parameters, break things, observe

## 📝 License

MIT License — Use freely for learning and teaching.

## 🙏 Acknowledgments

Content inspired by [Hello Interview](https://www.hellointerview.com/) System Design course.
