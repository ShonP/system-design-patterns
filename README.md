# 🏗️ System Design Labs

**57 hands-on labs · 220 Jupyter notebooks · Real Docker infrastructure**

Learn system design by running real code. Each lab includes Docker-based infrastructure, Python notebooks with working examples, and follows a **bad → better → best** teaching pattern.

## 🎯 What's Inside

| Category | Labs | Notebooks | Description |
|----------|------|-----------|-------------|
| [Core Concepts](#-core-concepts) | 8 | 30 | Fundamental building blocks |
| [Deep Dives](#-deep-dives) | 10 | 36 | Technology-specific deep dives |
| [System Designs](#-system-designs) | 27 | 93 | End-to-end system design problems |
| [Enterprise Patterns](#-enterprise-patterns) | 5 | 20 | Microsoft/enterprise-grade patterns |
| [Patterns](#-patterns) | 7 | 42 | Cross-cutting design patterns |
| **Total** | **57** | **220** | |

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
cd core-concepts/caching

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

## 📘 Core Concepts

Fundamental building blocks every engineer needs to know.

| Lab | Notebooks | Topics |
|-----|-----------|--------|
| [API Design](core-concepts/api-design/) | 4 | REST principles, pagination, rate limiting, versioning |
| [Caching](core-concepts/caching/) | 5 | Cache-aside, write-through, invalidation, TTL, stampede |
| [CAP Theorem](core-concepts/cap-theorem/) | 3 | Consistency vs availability, partition tolerance |
| [Consistent Hashing](core-concepts/consistent-hashing/) | 3 | Modulo → hash ring → virtual nodes (bad→better→best) |
| [Data Modeling](core-concepts/data-modeling/) | 4 | Relational, denormalization, NoSQL, schema evolution |
| [Networking Essentials](core-concepts/networking-essentials/) | 4 | DNS, load balancing, TCP/UDP, HTTP/2, TLS |
| [Numbers to Know](core-concepts/numbers-to-know/) | 3 | Latency benchmarks, throughput, back-of-envelope estimation |
| [Sharding](core-concepts/sharding/) | 4 | Hash-based, range-based, consistent hashing, rebalancing |

## 🔬 Deep Dives

Technology-specific deep dives with real infrastructure.

| Lab | Notebooks | Topics |
|-----|-----------|--------|
| [API Gateway](deep-dives/api-gateway/) | 3 | Routing, load balancing, rate limiting, auth (nginx) |
| [Cassandra](deep-dives/cassandra/) | 4 | Partition keys, wide rows, consistency levels, compaction |
| [DynamoDB](deep-dives/dynamodb/) | 4 | Partition/sort keys, GSI/LSI, single-table design, Streams |
| [Elasticsearch](deep-dives/elasticsearch/) | 4 | Full-text search, analyzers, aggregations, scaling |
| [Kafka](deep-dives/kafka/) | 4 | Producers/consumers, partitioning, exactly-once, Streams |
| [PostgreSQL](deep-dives/postgres/) | 4 | Indexing (bad→best), query optimization, replication, partitioning |
| [Redis](deep-dives/redis/) | 4 | Data structures, pub/sub, cache vs primary, cluster |
| [Time-Series Databases](deep-dives/time-series-databases/) | 3 | TimescaleDB, windowed aggregations, retention policies |
| [Vector Databases](deep-dives/vector-databases/) | 3 | pgvector, linear scan → IVFFlat → HNSW (bad→best) |
| [ZooKeeper](deep-dives/zookeeper/) | 3 | Distributed locks, leader election, config management |

## 🏛️ System Designs

Complete system design problems with hands-on implementations.

| Lab | Notebooks | Topics |
|-----|-----------|--------|
| [Ad Click Aggregator](system-designs/ad-click-aggregator/) | 3 | Click ingestion, real-time aggregation, deduplication |
| [Bitly (URL Shortener)](system-designs/bitly/) | 3 | URL encoding, redirect caching, analytics |
| [Distributed Cache](system-designs/distributed-cache/) | 3 | Cache partitioning, coherence, consistent hashing |
| [Dropbox (File Storage)](system-designs/dropbox/) | 4 | Chunked uploads, sync, deduplication, sharing |
| [FB Live Comments](system-designs/fb-live-comments/) | 3 | Real-time streaming, ordering, scaling |
| [FB News Feed](system-designs/fb-news-feed/) | 4 | Fan-out, ranking, social graph, feed caching |
| [FB Post Search](system-designs/fb-post-search/) | 3 | Full-text indexing, typeahead, search ranking |
| [Google Docs](system-designs/google-docs/) | 4 | OT, CRDTs, real-time collaboration, versioning |
| [Gopuff (Local Delivery)](system-designs/gopuff/) | 3 | Inventory, delivery routing, demand forecasting |
| [Instagram](system-designs/instagram/) | 4 | Photo pipeline, news feed, stories, explore |
| [Job Scheduler](system-designs/job-scheduler/) | 3 | Job queues, distributed execution, dead letter queues |
| [LeetCode](system-designs/leetcode/) | 3 | Code submission, sandboxed execution, leaderboards |
| [Metrics Monitoring](system-designs/metrics-monitoring/) | 3 | Prometheus, alerting, Grafana dashboards |
| [News Aggregator](system-designs/news-aggregator/) | 3 | RSS crawling, deduplication, personalized feeds |
| [Online Auction](system-designs/online-auction/) | 3 | Bid processing, auction lifecycle, real-time notifications |
| [Payment System](system-designs/payment-system/) | 4 | Processing pipeline, idempotency, ledger, fraud detection |
| [Rate Limiter](system-designs/rate-limiter/) | 4 | Token bucket, sliding window, distributed, API gateway |
| [Robinhood (Stock Trading)](system-designs/robinhood/) | 3 | Order matching, portfolio tracking, market data streaming |
| [Strava (Fitness Tracking)](system-designs/strava/) | 3 | GPS tracking, activity feed, segment leaderboards |
| [Ticketmaster](system-designs/ticketmaster/) | 4 | Seat locking, flash sales, reservation flow, scaling |
| [Tinder (Dating App)](system-designs/tinder/) | 3 | Geolocation matching, swipe system, notifications |
| [Top-K](system-designs/top-k/) | 3 | Count-min sketch, heap-based, distributed MapReduce |
| [Uber (Ride-Sharing)](system-designs/uber/) | 4 | Geospatial matching, driver tracking, surge pricing |
| [Web Crawler](system-designs/web-crawler/) | 4 | Basic crawler, fault tolerance, politeness, efficiency |
| [WhatsApp (Messaging)](system-designs/whatsapp/) | 4 | Message delivery, read receipts, groups, E2E encryption |
| [Yelp (Local Search)](system-designs/yelp/) | 3 | Geospatial search, reviews, search ranking |
| [YouTube (Video Streaming)](system-designs/youtube/) | 4 | Upload, streaming, processing, resumable uploads |

## 🏢 Enterprise Patterns

Production patterns used at Microsoft and large enterprises.

| Lab | Notebooks | Topics |
|-----|-----------|--------|
| [BCDR](enterprise-patterns/bcdr/) | 4 | RPO/RTO, replication failover, backup strategies, DR drills |
| [GDPR Paired Regions](enterprise-patterns/gdpr-paired-regions/) | 4 | Data residency, cross-region replication, right to erasure |
| [Long-Running Jobs (Temporal)](enterprise-patterns/long-running-jobs-temporal/) | 4 | Workflow engines, saga pattern, signals, versioning |
| [Privacy Review](enterprise-patterns/privacy-review/) | 4 | Data classification, PIA, anonymization, retention |
| [Security Review](enterprise-patterns/security-review/) | 4 | STRIDE, OWASP Top 10, secrets management, SDL |

## 🔄 Patterns

Cross-cutting design patterns (pre-existing).

| Pattern | Notebooks | Topics |
|---------|-----------|--------|
| [Real-Time Updates](patterns/real-time-updates/) | 7 | Polling, SSE, WebSockets, pub/sub |
| [Dealing with Contention](patterns/dealing-with-contention/) | 5 | Locks, optimistic concurrency, CRDTs |
| [Scaling Reads](patterns/scaling-reads/) | 6 | Caching, read replicas, materialized views |
| [Scaling Writes](patterns/scaling-writes/) | 6 | Sharding, partitioning, write buffering |
| [Handling Large Blobs](patterns/large-blobs/) | 6 | Chunked uploads, presigned URLs, CDN |
| [Long Running Tasks](patterns/long-running-tasks/) | 6 | Queues, workers, DLQ, backpressure |
| [Multi-Step Processes](patterns/multi-step-processes/) | 6 | Workflows, sagas, Temporal |

---

## 🏛️ Repository Structure

```
system-design-labs/
├── core-concepts/          # 8 fundamental concept labs
│   ├── caching/
│   ├── sharding/
│   └── ...
├── deep-dives/             # 10 technology deep dives
│   ├── redis/
│   ├── kafka/
│   └── ...
├── system-designs/         # 27 system design problems
│   ├── uber/
│   ├── instagram/
│   └── ...
├── enterprise-patterns/    # 5 enterprise/Microsoft patterns
│   ├── bcdr/
│   ├── gdpr-paired-regions/
│   └── ...
├── patterns/               # 7 cross-cutting patterns
│   ├── real-time-updates/
│   ├── scaling-reads/
│   └── ...
└── scraper/                # Content source (hellointerview.com)
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
