# Design Gurus Content Map

> Auto-generated from `tools/scraper/designgurus/content/` against the mapping rules in [`restructure-proposal.md`](./restructure-proposal.md) §6. Curate by editing this file directly; regenerate from `tools/` when the scraper refreshes.

**Total lessons mapped:** 503

## Summary by status

| Status | Count |
|---|---|
| enrich | 185 |
| new | 210 |
| skip/meta | 35 |
| unassigned | 73 |

## Summary by target lab

| Target lab | Lessons |
|---|---|
| `01-foundations/api-design` | 9 |
| `01-foundations/authentication-authorization` | 10 |
| `01-foundations/bloom-filters` | 7 |
| `01-foundations/caching` | 16 |
| `01-foundations/cap-theorem` | 9 |
| `01-foundations/cdn` | 5 |
| `01-foundations/consistent-hashing` | 3 |
| `01-foundations/data-modeling` | 16 |
| `01-foundations/id-generation` | 4 |
| `01-foundations/load-balancing` | 11 |
| `01-foundations/messaging-basics` | 11 |
| `01-foundations/networking-essentials` | 16 |
| `01-foundations/numbers-to-know` | 5 |
| `01-foundations/observability` | 8 |
| `01-foundations/replication` | 15 |
| `01-foundations/sharding` | 10 |
| `02-distributed-primitives/checksum` | 5 |
| `02-distributed-primitives/gossip-protocol` | 3 |
| `02-distributed-primitives/heartbeat` | 3 |
| `02-distributed-primitives/high-water-mark` | 1 |
| `02-distributed-primitives/hinted-handoff` | 1 |
| `02-distributed-primitives/lease` | 1 |
| `02-distributed-primitives/merkle-trees` | 2 |
| `02-distributed-primitives/phi-accrual-failure-detection` | 1 |
| `02-distributed-primitives/quorum` | 1 |
| `02-distributed-primitives/read-repair` | 2 |
| `02-distributed-primitives/segmented-log` | 1 |
| `02-distributed-primitives/split-brain-and-fencing` | 2 |
| `02-distributed-primitives/vector-clocks` | 2 |
| `02-distributed-primitives/write-ahead-log` | 2 |
| `03-technologies/coordination/zookeeper` | 10 |
| `03-technologies/databases/cassandra` | 9 |
| `03-technologies/databases/dynamodb` | 6 |
| `03-technologies/messaging/kafka` | 10 |
| `03-technologies/reference-systems/bigtable` | 12 |
| `03-technologies/reference-systems/gfs` | 16 |
| `03-technologies/reference-systems/hdfs` | 9 |
| `04-patterns/dealing-with-contention` | 1 |
| `04-patterns/idempotency` | 2 |
| `04-patterns/large-blobs` | 2 |
| `04-patterns/outbox-and-cdc` | 1 |
| `04-patterns/rate-limiting-and-throttling` | 1 |
| `04-patterns/real-time-updates` | 5 |
| `04-patterns/resilience` | 3 |
| `04-patterns/scaling-reads` | 1 |
| `04-patterns/scaling-writes` | 1 |
| `05-microservices/api-gateway` | 4 |
| `05-microservices/bff` | 3 |
| `05-microservices/bulkhead` | 2 |
| `05-microservices/circuit-breaker` | 2 |
| `05-microservices/configuration-externalization` | 2 |
| `05-microservices/cqrs` | 5 |
| `05-microservices/event-driven-architecture` | 4 |
| `05-microservices/retry` | 3 |
| `05-microservices/saga` | 5 |
| `05-microservices/service-discovery` | 5 |
| `05-microservices/sidecar` | 4 |
| `05-microservices/strangler` | 5 |
| `06-system-designs/ad-click-aggregator` | 2 |
| `06-system-designs/airbnb` | 1 |
| `06-system-designs/amazon-lambda` | 1 |
| `06-system-designs/bitly` | 2 |
| `06-system-designs/chatgpt` | 1 |
| `06-system-designs/code-deployment` | 1 |
| `06-system-designs/collaborative-whiteboard` | 1 |
| `06-system-designs/discord` | 1 |
| `06-system-designs/distributed-cache` | 1 |
| `06-system-designs/distributed-lock-manager` | 1 |
| `06-system-designs/dropbox` | 1 |
| `06-system-designs/fb-live-comments` | 1 |
| `06-system-designs/fb-news-feed` | 2 |
| `06-system-designs/fb-post-search` | 2 |
| `06-system-designs/flash-sale` | 1 |
| `06-system-designs/gmail` | 1 |
| `06-system-designs/google-calendar` | 1 |
| `06-system-designs/google-docs` | 1 |
| `06-system-designs/google-search` | 1 |
| `06-system-designs/instagram` | 1 |
| `06-system-designs/job-scheduler` | 1 |
| `06-system-designs/key-value-store` | 1 |
| `06-system-designs/leetcode` | 1 |
| `06-system-designs/linkedin-connections` | 2 |
| `06-system-designs/metrics-monitoring` | 1 |
| `06-system-designs/netflix` | 2 |
| `06-system-designs/news-aggregator` | 1 |
| `06-system-designs/notification-system` | 1 |
| `06-system-designs/payment-system` | 2 |
| `06-system-designs/rate-limiter` | 3 |
| `06-system-designs/reddit` | 1 |
| `06-system-designs/reminder-alert` | 1 |
| `06-system-designs/s3` | 1 |
| `06-system-designs/shopping-cart` | 1 |
| `06-system-designs/stock-exchange` | 1 |
| `06-system-designs/ticketmaster` | 1 |
| `06-system-designs/top-k` | 1 |
| `06-system-designs/typeahead-autocomplete` | 2 |
| `06-system-designs/uber` | 2 |
| `06-system-designs/web-crawler` | 1 |
| `06-system-designs/whatsapp` | 2 |
| `06-system-designs/yelp` | 1 |
| `06-system-designs/youtube` | 1 |
| `07-object-oriented-design/airline-management` | 1 |
| `07-object-oriented-design/amazon-shopping` | 1 |
| `07-object-oriented-design/atm` | 1 |
| `07-object-oriented-design/blackjack` | 1 |
| `07-object-oriented-design/car-rental` | 1 |
| `07-object-oriented-design/chess` | 1 |
| `07-object-oriented-design/cricinfo` | 1 |
| `07-object-oriented-design/facebook` | 1 |
| `07-object-oriented-design/hotel-management` | 1 |
| `07-object-oriented-design/library-management` | 1 |
| `07-object-oriented-design/linkedin` | 1 |
| `07-object-oriented-design/movie-ticket-booking` | 1 |
| `07-object-oriented-design/online-stock-brokerage` | 1 |
| `07-object-oriented-design/parking-lot` | 1 |
| `07-object-oriented-design/restaurant` | 1 |
| `07-object-oriented-design/stack-overflow` | 1 |
| `07-object-oriented-design/uml-basics` | 7 |
| `08-enterprise/bcdr` | 2 |
| `SKIP/meta` | 35 |
| `UNASSIGNED` | 73 |

## Full mapping

| Lesson slug | Course | Target lab | Status |
|---|---|---|---|
| `a-solution-to-the-monolithic-mayhem` | grokking-microservices-design-patterns | `05-microservices/strangler` | new |
| `advantages-of-api-gateway-pattern` | grokking-microservices-design-patterns | `05-microservices/api-gateway` | new |
| `api-gateway-pattern-an-example` | grokking-microservices-design-patterns | `05-microservices/api-gateway` | new |
| `bff-pattern-an-example` | grokking-microservices-design-patterns | `05-microservices/bff` | new |
| `bulkhead-pattern-a-example` | grokking-microservices-design-patterns | `05-microservices/bulkhead` | new |
| `circuit-breaker-pattern-an-example` | grokking-microservices-design-patterns | `05-microservices/circuit-breaker` | new |
| `conclusion-1-2-3-4` | grokking-microservices-design-patterns | `SKIP/meta` | skip/meta |
| `conclusion-1-2-3` | grokking-microservices-design-patterns | `SKIP/meta` | skip/meta |
| `conclusion-1-2` | grokking-microservices-design-patterns | `SKIP/meta` | skip/meta |
| `conclusion-1` | grokking-microservices-design-patterns | `SKIP/meta` | skip/meta |
| `conclusion` | grokking-microservices-design-patterns | `SKIP/meta` | skip/meta |
| `considerations-and-implications` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `cqrs-pattern-a-solution` | grokking-microservices-design-patterns | `05-microservices/cqrs` | new |
| `cqrs-pattern-an-example` | grokking-microservices-design-patterns | `05-microservices/cqrs` | new |
| `delving-into-code-an-example` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `embrace-the-future-of-software-architecture` | grokking-microservices-design-patterns | `SKIP/meta` | skip/meta |
| `eventdriven-architecture-a-promising-solution` | grokking-microservices-design-patterns | `05-microservices/event-driven-architecture` | new |
| `eventdriven-architecture-pattern-an-example` | grokking-microservices-design-patterns | `05-microservices/event-driven-architecture` | new |
| `introduction-1-2-3-4-5-6` | grokking-microservices-design-patterns | `SKIP/meta` | skip/meta |
| `introduction-1-2-3-4-5` | grokking-microservices-design-patterns | `SKIP/meta` | skip/meta |
| `introduction-1-2-3-4` | grokking-microservices-design-patterns | `SKIP/meta` | skip/meta |
| `introduction-1-2-3` | grokking-microservices-design-patterns | `SKIP/meta` | skip/meta |
| `introduction-1-2` | grokking-microservices-design-patterns | `SKIP/meta` | skip/meta |
| `introduction-1` | grokking-microservices-design-patterns | `SKIP/meta` | skip/meta |
| `introduction-to-bff` | grokking-microservices-design-patterns | `05-microservices/bff` | new |
| `introduction-to-saga-pattern` | grokking-microservices-design-patterns | `05-microservices/saga` | new |
| `introduction-to-the-api-gateway-pattern` | grokking-microservices-design-patterns | `05-microservices/api-gateway` | new |
| `introduction-to-the-sidecar-pattern` | grokking-microservices-design-patterns | `05-microservices/sidecar` | new |
| `introduction` | grokking-microservices-design-patterns | `SKIP/meta` | skip/meta |
| `issues-special-considerations-and-performance-implications` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `key-insights-and-implications` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `performance-implications-1-2-3-4` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `performance-implications-1-2-3` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `performance-implications-1-2` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `performance-implications-1` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `performance-implications-and-special-considerations-1-2-3` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `performance-implications-and-special-considerations-1-2` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `performance-implications-and-special-considerations-1` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `performance-implications-and-special-considerations` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `performance-implications` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `retry-pattern-an-example` | grokking-microservices-design-patterns | `05-microservices/retry` | new |
| `saga-pattern-a-example` | grokking-microservices-design-patterns | `05-microservices/saga` | new |
| `security-considerations` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `service-discovery-pattern-a-solution` | grokking-microservices-design-patterns | `05-microservices/service-discovery` | new |
| `service-discovery-pattern-an-example` | grokking-microservices-design-patterns | `05-microservices/service-discovery` | new |
| `sidecar-pattern-bringing-theory-to-practice-with-an-example` | grokking-microservices-design-patterns | `05-microservices/sidecar` | new |
| `strangler-pattern-a-detailed-example` | grokking-microservices-design-patterns | `05-microservices/strangler` | new |
| `summary` | grokking-microservices-design-patterns | `SKIP/meta` | skip/meta |
| `system-design-example` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `system-design-examples-1-2-3-4-5` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `system-design-examples-1-2-3-4` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `system-design-examples-1-2-3` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `system-design-examples-1-2` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `system-design-examples-1` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `system-design-examples-bringing-the-sidecar-pattern-to-life` | grokking-microservices-design-patterns | `05-microservices/sidecar` | new |
| `system-design-examples` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `the-architecture-of-the-bff-pattern` | grokking-microservices-design-patterns | `05-microservices/bff` | new |
| `the-architecture-of-the-cqrs-pattern` | grokking-microservices-design-patterns | `05-microservices/cqrs` | new |
| `the-architecture-of-the-eventdriven-architecture-pattern` | grokking-microservices-design-patterns | `05-microservices/event-driven-architecture` | new |
| `the-architecture-of-the-retry-pattern` | grokking-microservices-design-patterns | `05-microservices/retry` | new |
| `the-architecture-of-the-saga-pattern` | grokking-microservices-design-patterns | `05-microservices/saga` | new |
| `the-architecture-of-the-service-discovery-pattern` | grokking-microservices-design-patterns | `05-microservices/service-discovery` | new |
| `the-architecture-of-the-sidecar-pattern` | grokking-microservices-design-patterns | `05-microservices/sidecar` | new |
| `the-architecture-of-the-strangler-pattern` | grokking-microservices-design-patterns | `05-microservices/strangler` | new |
| `the-architecture` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `the-bulkhead-pattern-a-solution` | grokking-microservices-design-patterns | `05-microservices/bulkhead` | new |
| `the-circuit-breaker-pattern-an-effective-shield-against-cascading-failures` | grokking-microservices-design-patterns | `05-microservices/circuit-breaker` | new |
| `the-course-at-a-glance` | grokking-microservices-design-patterns | `SKIP/meta` | skip/meta |
| `the-inner-workings-of-the-cqrs-pattern` | grokking-microservices-design-patterns | `05-microservices/cqrs` | new |
| `the-inner-workings-of-the-eventdriven-architecture-pattern` | grokking-microservices-design-patterns | `05-microservices/event-driven-architecture` | new |
| `the-inner-workings-of-the-saga-pattern` | grokking-microservices-design-patterns | `05-microservices/saga` | new |
| `the-inner-workings-of-the-service-discovery-pattern` | grokking-microservices-design-patterns | `05-microservices/service-discovery` | new |
| `the-inner-workings` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `the-problem-configuration-management-in-a-microservices-architecture` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `the-problem-failure-propagation-in-distributed-systems` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `the-problem-legacy-systems` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `the-problem-managing-complex-interactions-in-distributed-systems` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `the-problem-monolithic-application-management` | grokking-microservices-design-patterns | `05-microservices/strangler` | new |
| `the-problem-service-coordination-in-distributed-systems` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `the-problem-the-struggles-of-distributed-systems-and-service-failures` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `the-problem-traditional-backend-models` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `the-problem-traditional-crud-operations` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `the-problem-traditional-transaction-models` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `the-retry-pattern-a-solution` | grokking-microservices-design-patterns | `05-microservices/retry` | new |
| `the-saga-pattern-a-solution` | grokking-microservices-design-patterns | `05-microservices/saga` | new |
| `the-solution-configuration-externalization-pattern` | grokking-microservices-design-patterns | `05-microservices/configuration-externalization` | new |
| `the-strangler-pattern-a-solution` | grokking-microservices-design-patterns | `05-microservices/strangler` | new |
| `unveiling-the-architecture-how-does-configuration-externalization-work` | grokking-microservices-design-patterns | `05-microservices/configuration-externalization` | new |
| `use-cases-and-realworld-examples` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `use-cases-and-system-design-examples-1` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `use-cases-and-system-design-examples` | grokking-microservices-design-patterns | `UNASSIGNED` | unassigned |
| `what-is-service-discovery-pattern` | grokking-microservices-design-patterns | `05-microservices/service-discovery` | new |
| `who-should-take-this-course` | grokking-microservices-design-patterns | `SKIP/meta` | skip/meta |
| `68edf4b408a6d64577448e89 — *What is Little’s Law and How to Use It for Quick Capacity Estimates in System Design*` | grokking-scalable-systems-for-interviews | `01-foundations/numbers-to-know` | enrich |
| `68edf8c1b6ae1f7ce1ce2e24 — *How Can I do Back-of-the-Envelope Sizing for QPS, Bandwidth, Storage, and Peak vs. Average Load?*` | grokking-scalable-systems-for-interviews | `01-foundations/numbers-to-know` | enrich |
| `68edfa8e2c92a180ee33f5a4 — *What are Cold Starts and Warm Starts, and Why Do They Matter for Performance?*` | grokking-scalable-systems-for-interviews | `04-patterns/resilience` | new |
| `68edfb9617a5835560f5b56c — *What Are Sticky Sessions (Session Affinity) and When Should I Avoid Them?*` | grokking-scalable-systems-for-interviews | `01-foundations/load-balancing` | new |
| `68edfd92b6ae1f7ce1ce6c01 — *What Is the Difference between Liveness Checks and Readiness Checks in Load Balancers?*` | grokking-scalable-systems-for-interviews | `01-foundations/load-balancing` | new |
| `68edff147d36d73845b59395 — *What is Global Server Load Balancing (GSLB) and How GeoDNS and Anycast Work?*` | grokking-scalable-systems-for-interviews | `01-foundations/networking-essentials` | enrich |
| `68ee037b062942252902fb8f — *What are the Main API Pagination Strategies (offset, cursor, keyset), and When Should I Use Each?*` | grokking-scalable-systems-for-interviews | `01-foundations/api-design` | enrich |
| `68ee05fdd26c8ead03e59dfa — *What are HTTP Conditional Requests (ETag, If‑None‑Match, Last‑Modified) and How They Reduce Load?*` | grokking-scalable-systems-for-interviews | `01-foundations/api-design` | enrich |
| `68ee09c22c2f8a749afae99f — *What Are Idempotency Keys and How to Implement Them Safely for Payments*` | grokking-scalable-systems-for-interviews | `04-patterns/idempotency` | new |
| `68ee0afb7852e8f5441bfa95 — *What Is the Difference between Rate Limiting and Throttling and Quotas?*` | grokking-scalable-systems-for-interviews | `04-patterns/rate-limiting-and-throttling` | new |
| `68ee12ccf78c043f2d1e8ce6 — *What are SQL Isolation Levels (Read Committed, Repeatable Read, Serializable), and What Anomalies Do They Prevent?*` | grokking-scalable-systems-for-interviews | `01-foundations/data-modeling` | enrich |
| `68eeb6caca6e723c538ff352 — *What Is MVCC (Multi‑Version Concurrency Control), and How Does It Enable Concurrent Reads and Writes?*` | grokking-scalable-systems-for-interviews | `01-foundations/data-modeling` | enrich |
| `68eeb990ca6e723c53900f4f — *What Is a Write‑Ahead Log (WAL), and How Does It Ensure Durability?*` | grokking-scalable-systems-for-interviews | `02-distributed-primitives/write-ahead-log` | new |
| `68eebc57c67a1fb4ce9699c4 — *What Is the Difference Between Synchronous and Asynchronous Replication, and When Should I Use Read Replicas?*` | grokking-scalable-systems-for-interviews | `01-foundations/replication` | new |
| `68eebe3b01f404fe834f8b4a — *What Are Safe Patterns for Online Schema Changes vs. Offline Migrations?*` | grokking-scalable-systems-for-interviews | `01-foundations/data-modeling` | enrich |
| `68eff95f7faacc86b2175118 — *How Do I Choose a Good Shard Key and Avoid Hotspots (Bucketing and Key Randomization)?*` | grokking-scalable-systems-for-interviews | `01-foundations/sharding` | enrich |
| `68effb8dda6e561f0b09bad0 — *What Is the Difference Between Rendezvous Hashing and Consistent Hashing, and When Should I Use Each?*` | grokking-scalable-systems-for-interviews | `01-foundations/consistent-hashing` | enrich |
| `68effd757faacc86b2177a89 — *What Are Range Sharding, Directory‑Based Sharding, and Geo‑Sharding, and What Are the Common Use Cases?*` | grokking-scalable-systems-for-interviews | `01-foundations/sharding` | enrich |
| `68efff664e411c5519b4835e — *What Is Negative Caching and When Should You Cache 404 or Empty Results?*` | grokking-scalable-systems-for-interviews | `01-foundations/caching` | enrich |
| `68f000407faacc86b2179f29 — *What Is the Difference Between Soft TTL and Hard TTL, and Why Does It Matter?*` | grokking-scalable-systems-for-interviews | `01-foundations/caching` | enrich |
| `68f004790eb1d07385216f8f — *How Can a Bloom Filter Reduce Cache or Database Load?*` | grokking-scalable-systems-for-interviews | `01-foundations/bloom-filters` | new |
| `68f15b79417a412009f5ad15 — *What Is Distributed Locking for Cache Rebuilds, and How Does It Prevent Cache Stampedes?*` | grokking-scalable-systems-for-interviews | `01-foundations/caching` | enrich |
| `68f15d1bcd4289bf36842532 — *What Do At‑most‑once, At‑least‑once, And Exactly‑once Delivery Semantics Mean?*` | grokking-scalable-systems-for-interviews | `01-foundations/messaging-basics` | new |
| `68f15e21cd4289bf36842a11 — *What Are Idempotent Producers And Consumers, And How Do De‑duplication Keys Work?*` | grokking-scalable-systems-for-interviews | `01-foundations/messaging-basics` | new |
| `68f15ec6e9e259090e6d3b27 — *What Is Message Ordering, How Do Partition Keys Affect It, And When Can Ordering Break?*` | grokking-scalable-systems-for-interviews | `01-foundations/messaging-basics` | new |
| `68f15f774fb0057f96530b55 — *What Are Windowing And Watermarking In Streaming Systems, In Simple Terms?*` | grokking-scalable-systems-for-interviews | `04-patterns/scaling-writes` | enrich |
| `68f1605373c29ce787a631a1 — *What Is Quorum (N, R, W), And Why Does R + W > N Give Strongly Consistent Reads?*` | grokking-scalable-systems-for-interviews | `02-distributed-primitives/quorum` | new |
| `68f2f55261252e614587c3d5 — *What Are Common Conflict Resolution Strategies (Last‑write‑wins, Vector Clocks, Logical Clocks)?*` | grokking-scalable-systems-for-interviews | `04-patterns/dealing-with-contention` | enrich |
| `68f2f650e6a1bbeface9f7dd — *What Are Read Repair, Hinted Handoff, And Anti‑entropy (Merkle Trees) In Eventually Consistent Systems?*` | grokking-scalable-systems-for-interviews | `02-distributed-primitives/read-repair` | new |
| `68f2f76036c8da7d2862d5ab — *What Is The Difference Between SLI, SLO, And SLA, And Can You Give Simple Examples?*` | grokking-scalable-systems-for-interviews | `01-foundations/observability` | new |
| `68f2f81061252e614587e2a4 — *What Is Opentelemetry, And How Do Traces, Spans, Metrics, And Logs Fit Together?*` | grokking-scalable-systems-for-interviews | `01-foundations/observability` | new |
| `68f2f8eb8c8a4b4901febec9 — *What Is An Error Budget, And How Should It Guide Release Decisions?*` | grokking-scalable-systems-for-interviews | `01-foundations/observability` | new |
| `68f2f9aacb4b1bf813d1bdf8 — *What Are The Trade‑offs Between Server‑stored Sessions And JWTs for Authentication?*` | grokking-scalable-systems-for-interviews | `01-foundations/authentication-authorization` | new |
| `68f3bf9f94647ee93cd3e3d6 — *What Is The Difference Between TLS And MTLS, And When Is MTLS Appropriate For Service‑to‑service Auth?*` | grokking-scalable-systems-for-interviews | `01-foundations/authentication-authorization` | new |
| `68f3c063d657c1894f8a547d — *What Is Secrets Management, And How Do Environment Variables, KMS, And Vault Compare?*` | grokking-scalable-systems-for-interviews | `01-foundations/authentication-authorization` | new |
| `68f3c1667d5dc55ba26d55b7 — *What Is A Replay Attack, And How Is It Different from Idempotency Issues?*` | grokking-scalable-systems-for-interviews | `04-patterns/idempotency` | new |
| `68f3c27ac9ceb80f7fb370a3 — *What Are The Differences Between TCP, UDP, And QUIC, And When Should I Use Each?*` | grokking-scalable-systems-for-interviews | `01-foundations/networking-essentials` | enrich |
| `68f3c30e9e68bb62b0535170 — *What Is The Difference Between A Forward Proxy, A Reverse Proxy, And NAT?*` | grokking-scalable-systems-for-interviews | `01-foundations/networking-essentials` | enrich |
| `68f3c39c2d032c2bc4ee2232 — *What Changed From HTTP/1.1 To HTTP/2 To HTTP/3, And What Are Head‑of‑line Blocking And Multiplexing?*` | grokking-scalable-systems-for-interviews | `01-foundations/networking-essentials` | enrich |
| `68f54326348ad769dfb6d9b7 — *What Is the Difference Between Content‑Addressable Storage and Location‑Based Addressing?*` | grokking-scalable-systems-for-interviews | `04-patterns/large-blobs` | enrich |
| `68f5441e361be107be008372 — *What Are Checksums and Etags, and How Do MD5/SHA Compare to CRC for Integrity?*` | grokking-scalable-systems-for-interviews | `02-distributed-primitives/checksum` | new |
| `68f544a9108478dd513ddaf6 — *What Are Hot, Warm, Cold, and Archive Storage Tiers, and When Should I Use Each?*` | grokking-scalable-systems-for-interviews | `04-patterns/large-blobs` | enrich |
| `68f545ca2b1a1b07d684fcf4 — *What Is the Outbox Pattern, and How Does Change Data Capture (CDC) Work at a High Level?*` | grokking-scalable-systems-for-interviews | `04-patterns/outbox-and-cdc` | new |
| `68f5469830668094289ddc52 — *What Is CQRS (Command Query Responsibility Segregation), and When Should I Consider It?*` | grokking-scalable-systems-for-interviews | `05-microservices/cqrs` | new |
| `68f547a14262c96e27e8aea8 — *What Are the Differences Between a Circuit Breaker, Retry With Backoff, and Rate Limiting?*` | grokking-scalable-systems-for-interviews | `04-patterns/resilience` | new |
| `68f68405e8edc1e909ca3936 — *What Are RPO and RTO, and How Do They Differ in Disaster Recovery Planning?*` | grokking-scalable-systems-for-interviews | `08-enterprise/bcdr` | enrich |
| `68f684f3f6e9e255b56640a8 — *What Is the Difference Between Active‑Active and Active‑Passive Architectures?*` | grokking-scalable-systems-for-interviews | `08-enterprise/bcdr` | enrich |
| `68f68c9221e873a3cc023978 — *What Is Graceful Degradation, and How Do Feature Flags Help Availability?*` | grokking-scalable-systems-for-interviews | `04-patterns/resilience` | new |
| `68f68db6a5c677845def2344 — *What Are the Differences Between UUID, ULID, KSUID, and Snowflake IDs, and How Do I Choose?*` | grokking-scalable-systems-for-interviews | `01-foundations/id-generation` | new |
| `68f68ec4cc63a6c343c9149f — *How Do Snowflake‑Style IDs Work (Timestamp, Worker, Sequence), and What Problems Do They Solve?*` | grokking-scalable-systems-for-interviews | `01-foundations/id-generation` | new |
| `68f68fe2a5c677845def3a3b — *What Is the Difference Between Wall‑Clock Time and Monotonic Time, and Why Is Clock Skew Hard?*` | grokking-scalable-systems-for-interviews | `01-foundations/id-generation` | new |
| `68f78c5204ef556370f3c467 — *Course Overview*` | grokking-scalable-systems-for-interviews | `UNASSIGNED` | unassigned |
| `68f78d6a08acc3c5c0030b5a — *Who This Course Is for*` | grokking-scalable-systems-for-interviews | `UNASSIGNED` | unassigned |
| `68f78ea408acc3c5c0032cd0 — *What To Learn Next*` | grokking-scalable-systems-for-interviews | `UNASSIGNED` | unassigned |
| `68f79a2c08acc3c5c00393b7 — *You now understand*` | grokking-scalable-systems-for-interviews | `UNASSIGNED` | unassigned |
| `68f79a9a14c2c28ffe762b19 — *More importantly, you’ve developed the*` | grokking-scalable-systems-for-interviews | `UNASSIGNED` | unassigned |
| `acid-vs-base-properties` | grokking-system-design-fundamentals | `01-foundations/data-modeling` | enrich |
| `advantages-and-disadvantages-of-using-api-gateway` | grokking-system-design-fundamentals | `01-foundations/api-design` | enrich |
| `applications-of-bloom-filters` | grokking-system-design-fundamentals | `01-foundations/bloom-filters` | new |
| `architecture-of-a-distributed-file-system` | grokking-system-design-fundamentals | `UNASSIGNED` | unassigned |
| `authentication-vs-authorization` | grokking-system-design-fundamentals | `01-foundations/authentication-authorization` | new |
| `availability` | grokking-system-design-fundamentals | `01-foundations/observability` | new |
| `batch-processing-vs-stream-processing` | grokking-system-design-fundamentals | `UNASSIGNED` | unassigned |
| `benefits-limitations-of-bloom-filters` | grokking-system-design-fundamentals | `01-foundations/bloom-filters` | new |
| `benefits-of-data-partitioning` | grokking-system-design-fundamentals | `01-foundations/sharding` | enrich |
| `beyond-cap-theorem` | grokking-system-design-fundamentals | `01-foundations/cap-theorem` | enrich |
| `cache-coherence-and-consistency-models` | grokking-system-design-fundamentals | `01-foundations/caching` | enrich |
| `cache-invalidation` | grokking-system-design-fundamentals | `01-foundations/caching` | enrich |
| `cache-performance-metrics` | grokking-system-design-fundamentals | `01-foundations/caching` | enrich |
| `cache-read-strategies` | grokking-system-design-fundamentals | `01-foundations/caching` | enrich |
| `cache-replacement-policies` | grokking-system-design-fundamentals | `01-foundations/caching` | enrich |
| `caching-challenges` | grokking-system-design-fundamentals | `01-foundations/caching` | enrich |
| `cdn-architecture` | grokking-system-design-fundamentals | `01-foundations/cdn` | new |
| `challenges-of-load-balancers` | grokking-system-design-fundamentals | `01-foundations/load-balancing` | new |
| `common-problems-associated-with-data-partitioning` | grokking-system-design-fundamentals | `01-foundations/sharding` | enrich |
| `components-of-cap-theorem` | grokking-system-design-fundamentals | `01-foundations/cap-theorem` | enrich |
| `concurrency-and-coordination` | grokking-system-design-fundamentals | `UNASSIGNED` | unassigned |
| `data-backup-vs-disaster-recovery` | grokking-system-design-fundamentals | `UNASSIGNED` | unassigned |
| `data-replication-vs-data-mirroring` | grokking-system-design-fundamentals | `01-foundations/replication` | new |
| `data-sharding-techniques` | grokking-system-design-fundamentals | `01-foundations/sharding` | enrich |
| `database-federation` | grokking-system-design-fundamentals | `01-foundations/sharding` | enrich |
| `difference-between-longpolling-websockets-and-serversent-events` | grokking-system-design-fundamentals | `04-patterns/real-time-updates` | enrich |
| `dns-load-balancing-and-high-availability` | grokking-system-design-fundamentals | `01-foundations/networking-essentials` | enrich |
| `dns-resolution-process` | grokking-system-design-fundamentals | `01-foundations/networking-essentials` | enrich |
| `eventdriven-vs-polling-architecture` | grokking-system-design-fundamentals | `04-patterns/real-time-updates` | enrich |
| `examples-of-cap-theorem-in-practice` | grokking-system-design-fundamentals | `01-foundations/cap-theorem` | enrich |
| `fault-tolerance-vs-high-availability` | grokking-system-design-fundamentals | `01-foundations/observability` | new |
| `high-availability-and-fault-tolerance` | grokking-system-design-fundamentals | `01-foundations/observability` | new |
| `http-10-vs-11-vs-20-vs-30` | grokking-system-design-fundamentals | `01-foundations/networking-essentials` | enrich |
| `http-vs-https` | grokking-system-design-fundamentals | `01-foundations/networking-essentials` | enrich |
| `inmemory-database-vs-ondisk-database` | grokking-system-design-fundamentals | `01-foundations/data-modeling` | enrich |
| `introduction-to-api-gateway` | grokking-system-design-fundamentals | `01-foundations/api-design` | enrich |
| `introduction-to-bloom-filters` | grokking-system-design-fundamentals | `01-foundations/bloom-filters` | new |
| `introduction-to-caching` | grokking-system-design-fundamentals | `01-foundations/caching` | enrich |
| `introduction-to-cap-theorem` | grokking-system-design-fundamentals | `01-foundations/cap-theorem` | enrich |
| `introduction-to-data-partitioning` | grokking-system-design-fundamentals | `01-foundations/sharding` | enrich |
| `introduction-to-databases` | grokking-system-design-fundamentals | `01-foundations/data-modeling` | enrich |
| `introduction-to-dns` | grokking-system-design-fundamentals | `01-foundations/networking-essentials` | enrich |
| `introduction-to-kafka` | grokking-system-design-fundamentals | `01-foundations/messaging-basics` | new |
| `introduction-to-load-balancing` | grokking-system-design-fundamentals | `01-foundations/load-balancing` | new |
| `introduction-to-messaging-system` | grokking-system-design-fundamentals | `01-foundations/messaging-basics` | new |
| `introduction-to-system-design` | grokking-system-design-fundamentals | `SKIP/meta` | skip/meta |
| `key-components-of-a-dfs` | grokking-system-design-fundamentals | `UNASSIGNED` | unassigned |
| `latency-and-performance` | grokking-system-design-fundamentals | `01-foundations/numbers-to-know` | enrich |
| `load-balancer-types` | grokking-system-design-fundamentals | `01-foundations/load-balancing` | new |
| `load-balancing-algorithms` | grokking-system-design-fundamentals | `01-foundations/load-balancing` | new |
| `message-queues-vs-service-bus` | grokking-system-design-fundamentals | `01-foundations/messaging-basics` | new |
| `messaging-patterns` | grokking-system-design-fundamentals | `01-foundations/messaging-basics` | new |
| `microservices-vs-serverless-architecture` | grokking-system-design-fundamentals | `UNASSIGNED` | unassigned |
| `monitoring-and-observability` | grokking-system-design-fundamentals | `01-foundations/observability` | new |
| `nosql-databases` | grokking-system-design-fundamentals | `01-foundations/data-modeling` | enrich |
| `oauth-vs-jwt-for-authentication` | grokking-system-design-fundamentals | `01-foundations/authentication-authorization` | new |
| `origin-server-vs-edge-server` | grokking-system-design-fundamentals | `01-foundations/cdn` | new |
| `partitioning-methods` | grokking-system-design-fundamentals | `01-foundations/sharding` | enrich |
| `popular-messaging-queue-systems` | grokking-system-design-fundamentals | `01-foundations/messaging-basics` | new |
| `push-cdn-vs-pull-cdn` | grokking-system-design-fundamentals | `01-foundations/cdn` | new |
| `push-vs-pull-notification-systems` | grokking-system-design-fundamentals | `04-patterns/real-time-updates` | enrich |
| `quiz` | grokking-system-design-fundamentals | `SKIP/meta` | skip/meta |
| `rabbitmq-vs-kafka-vs-activemq` | grokking-system-design-fundamentals | `01-foundations/messaging-basics` | new |
| `realworld-examples-and-case-studies` | grokking-system-design-fundamentals | `SKIP/meta` | skip/meta |
| `replication-methods` | grokking-system-design-fundamentals | `01-foundations/replication` | new |
| `resilience-and-error-handling` | grokking-system-design-fundamentals | `01-foundations/observability` | new |
| `scalability-and-performance-1` | grokking-system-design-fundamentals | `UNASSIGNED` | unassigned |
| `scalability-and-performance` | grokking-system-design-fundamentals | `UNASSIGNED` | unassigned |
| `scalability` | grokking-system-design-fundamentals | `UNASSIGNED` | unassigned |
| `sql-databases` | grokking-system-design-fundamentals | `01-foundations/data-modeling` | enrich |
| `sql-normalization-and-denormalization` | grokking-system-design-fundamentals | `01-foundations/data-modeling` | enrich |
| `sql-vs-nosql` | grokking-system-design-fundamentals | `01-foundations/data-modeling` | enrich |
| `stateful-vs-stateless-architecture` | grokking-system-design-fundamentals | `UNASSIGNED` | unassigned |
| `stateless-vs-stateful-load-balancing` | grokking-system-design-fundamentals | `01-foundations/load-balancing` | new |
| `synchronous-vs-asynchronous-communication` | grokking-system-design-fundamentals | `01-foundations/messaging-basics` | new |
| `system-design-tradeoffs-in-interviews` | grokking-system-design-fundamentals | `SKIP/meta` | skip/meta |
| `tcp-vs-udp` | grokking-system-design-fundamentals | `01-foundations/networking-essentials` | enrich |
| `tradeoffs-in-distributed-systems` | grokking-system-design-fundamentals | `SKIP/meta` | skip/meta |
| `types-of-caching` | grokking-system-design-fundamentals | `01-foundations/caching` | enrich |
| `types-of-indexes` | grokking-system-design-fundamentals | `01-foundations/data-modeling` | enrich |
| `url-vs-uri-vs-urn` | grokking-system-design-fundamentals | `01-foundations/networking-essentials` | enrich |
| `usage-of-api-gateway` | grokking-system-design-fundamentals | `01-foundations/api-design` | enrich |
| `uses-of-checksum` | grokking-system-design-fundamentals | `02-distributed-primitives/checksum` | new |
| `uses-of-load-balancing` | grokking-system-design-fundamentals | `01-foundations/load-balancing` | new |
| `uses-of-proxies` | grokking-system-design-fundamentals | `01-foundations/networking-essentials` | enrich |
| `variants-and-extensions-of-bloom-filters` | grokking-system-design-fundamentals | `01-foundations/bloom-filters` | new |
| `vpn-vs-proxy-server` | grokking-system-design-fundamentals | `01-foundations/networking-essentials` | enrich |
| `what-are-ddos-attacks` | grokking-system-design-fundamentals | `01-foundations/authentication-authorization` | new |
| `what-are-indexes` | grokking-system-design-fundamentals | `01-foundations/data-modeling` | enrich |
| `what-is-a-distributed-file-system` | grokking-system-design-fundamentals | `UNASSIGNED` | unassigned |
| `what-is-a-proxy-server` | grokking-system-design-fundamentals | `01-foundations/networking-essentials` | enrich |
| `what-is-authentication` | grokking-system-design-fundamentals | `01-foundations/authentication-authorization` | new |
| `what-is-authorization` | grokking-system-design-fundamentals | `01-foundations/authentication-authorization` | new |
| `what-is-cdn` | grokking-system-design-fundamentals | `01-foundations/cdn` | new |
| `what-is-checksum` | grokking-system-design-fundamentals | `02-distributed-primitives/checksum` | new |
| `what-is-encryption` | grokking-system-design-fundamentals | `01-foundations/authentication-authorization` | new |
| `what-is-heartbeat` | grokking-system-design-fundamentals | `02-distributed-primitives/heartbeat` | new |
| `what-is-leader-and-follower-pattern` | grokking-system-design-fundamentals | `01-foundations/replication` | new |
| `what-is-quorum` | grokking-system-design-fundamentals | `01-foundations/replication` | new |
| `what-is-redundancy` | grokking-system-design-fundamentals | `01-foundations/replication` | new |
| `what-is-replication` | grokking-system-design-fundamentals | `01-foundations/replication` | new |
| `what-is-security-and-privacy` | grokking-system-design-fundamentals | `01-foundations/authentication-authorization` | new |
| `why-is-caching-important` | grokking-system-design-fundamentals | `01-foundations/caching` | enrich |
| `xml-vs-json` | grokking-system-design-fundamentals | `01-foundations/api-design` | enrich |
| `course-overview-audience-scope-and-content` | grokking-system-design-interview-ii | `SKIP/meta` | skip/meta |
| `design-a-flash-sale-for-an-ecommerce-site` | grokking-system-design-interview-ii | `06-system-designs/flash-sale` | new |
| `design-a-recommendation-system-for-netflix` | grokking-system-design-interview-ii | `06-system-designs/netflix` | new |
| `design-a-reminder-alert-system` | grokking-system-design-interview-ii | `06-system-designs/reminder-alert` | new |
| `design-code-judging-system-like-leetcode` | grokking-system-design-interview-ii | `06-system-designs/leetcode` | enrich |
| `design-global-news-aggregator-system-like-google-news` | grokking-system-design-interview-ii | `06-system-designs/news-aggregator` | enrich |
| `design-gmail-rafay` | grokking-system-design-interview-ii | `06-system-designs/gmail` | new |
| `design-google-calendar` | grokking-system-design-interview-ii | `06-system-designs/google-calendar` | new |
| `design-payment-system` | grokking-system-design-interview-ii | `06-system-designs/payment-system` | enrich |
| `design-reddit-new` | grokking-system-design-interview-ii | `06-system-designs/reddit` | new |
| `design-unique-id-generator` | grokking-system-design-interview-ii | `01-foundations/id-generation` | new |
| `designing-a-notification-system` | grokking-system-design-interview-ii | `06-system-designs/notification-system` | new |
| `youtube-counter` | grokking-system-design-interview-ii | `06-system-designs/top-k` | enrich |
| `1-bloom-filters` | grokking-the-advanced-system-design-interview | `01-foundations/bloom-filters` | new |
| `10-gossip-protocol` | grokking-the-advanced-system-design-interview | `02-distributed-primitives/gossip-protocol` | new |
| `11-phi-accrual-failure-detection` | grokking-the-advanced-system-design-interview | `02-distributed-primitives/phi-accrual-failure-detection` | new |
| `12-split-brain` | grokking-the-advanced-system-design-interview | `02-distributed-primitives/split-brain-and-fencing` | new |
| `13-fencing` | grokking-the-advanced-system-design-interview | `02-distributed-primitives/split-brain-and-fencing` | new |
| `14-checksum` | grokking-the-advanced-system-design-interview | `02-distributed-primitives/checksum` | new |
| `15-vector-clocks` | grokking-the-advanced-system-design-interview | `02-distributed-primitives/vector-clocks` | new |
| `16-cap-theorem` | grokking-the-advanced-system-design-interview | `01-foundations/cap-theorem` | enrich |
| `17-pacelc-theorem` | grokking-the-advanced-system-design-interview | `01-foundations/cap-theorem` | enrich |
| `18-hinted-handoff` | grokking-the-advanced-system-design-interview | `02-distributed-primitives/hinted-handoff` | new |
| `19-read-repair` | grokking-the-advanced-system-design-interview | `02-distributed-primitives/read-repair` | new |
| `2-consistent-hashing` | grokking-the-advanced-system-design-interview | `01-foundations/consistent-hashing` | enrich |
| `20-merkle-trees` | grokking-the-advanced-system-design-interview | `02-distributed-primitives/merkle-trees` | new |
| `3-quorum` | grokking-the-advanced-system-design-interview | `01-foundations/replication` | new |
| `4-leader-and-follower` | grokking-the-advanced-system-design-interview | `01-foundations/replication` | new |
| `5-writeahead-log` | grokking-the-advanced-system-design-interview | `02-distributed-primitives/write-ahead-log` | new |
| `6-segmented-log` | grokking-the-advanced-system-design-interview | `02-distributed-primitives/segmented-log` | new |
| `7-highwater-mark` | grokking-the-advanced-system-design-interview | `02-distributed-primitives/high-water-mark` | new |
| `8-lease` | grokking-the-advanced-system-design-interview | `02-distributed-primitives/lease` | new |
| `9-heartbeat` | grokking-the-advanced-system-design-interview | `02-distributed-primitives/heartbeat` | new |
| `anatomy-of-a-read-operation-1` | grokking-the-advanced-system-design-interview | `UNASSIGNED` | unassigned |
| `anatomy-of-a-read-operation` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/gfs` | new |
| `anatomy-of-a-write-operation-1` | grokking-the-advanced-system-design-interview | `UNASSIGNED` | unassigned |
| `anatomy-of-a-write-operation` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/gfs` | new |
| `anatomy-of-an-append-operation` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/gfs` | new |
| `anatomy-of-cassandras-read-operation` | grokking-the-advanced-system-design-interview | `03-technologies/databases/cassandra` | enrich |
| `anatomy-of-cassandras-write-operation` | grokking-the-advanced-system-design-interview | `03-technologies/databases/cassandra` | enrich |
| `antientropy-through-merkle-trees` | grokking-the-advanced-system-design-interview | `02-distributed-primitives/merkle-trees` | new |
| `bigtable-characteristics` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/bigtable` | new |
| `bigtable-components` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/bigtable` | new |
| `bigtable-data-model` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/bigtable` | new |
| `bigtable-introduction` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/bigtable` | new |
| `bigtable-refinements` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/bigtable` | new |
| `caching` | grokking-the-advanced-system-design-interview | `01-foundations/caching` | enrich |
| `cassandra-consistency-levels` | grokking-the-advanced-system-design-interview | `03-technologies/databases/cassandra` | enrich |
| `cassandra-introduction` | grokking-the-advanced-system-design-interview | `03-technologies/databases/cassandra` | enrich |
| `chubby-introduction` | grokking-the-advanced-system-design-interview | `03-technologies/coordination/zookeeper` | enrich |
| `compaction` | grokking-the-advanced-system-design-interview | `03-technologies/databases/cassandra` | enrich |
| `consumer-groups` | grokking-the-advanced-system-design-interview | `03-technologies/messaging/kafka` | enrich |
| `controller-broker` | grokking-the-advanced-system-design-interview | `03-technologies/messaging/kafka` | enrich |
| `criticism-on-gfs` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/gfs` | new |
| `data-integrity-caching` | grokking-the-advanced-system-design-interview | `UNASSIGNED` | unassigned |
| `data-partitioning` | grokking-the-advanced-system-design-interview | `01-foundations/sharding` | enrich |
| `database` | grokking-the-advanced-system-design-interview | `UNASSIGNED` | unassigned |
| `deep-dive` | grokking-the-advanced-system-design-interview | `UNASSIGNED` | unassigned |
| `design-rationale` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/gfs` | new |
| `dynamo-characteristics-and-criticism` | grokking-the-advanced-system-design-interview | `03-technologies/databases/dynamodb` | enrich |
| `dynamo-introduction` | grokking-the-advanced-system-design-interview | `03-technologies/databases/dynamodb` | enrich |
| `fault-tolerance-and-compaction` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/gfs` | new |
| `fault-tolerance-high-availability-and-data-integrity` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/hdfs` | new |
| `fault-tolerance` | grokking-the-advanced-system-design-interview | `UNASSIGNED` | unassigned |
| `file-directories-and-handles` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/hdfs` | new |
| `garbage-collection` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/bigtable` | new |
| `gfs-and-chubby` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/gfs` | new |
| `gfs-consistency-model-and-snapshotting` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/gfs` | new |
| `google-file-system-introduction` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/gfs` | new |
| `gossip-protocol` | grokking-the-advanced-system-design-interview | `02-distributed-primitives/gossip-protocol` | new |
| `gossiper` | grokking-the-advanced-system-design-interview | `02-distributed-primitives/gossip-protocol` | new |
| `hadoop-distributed-file-system-introduction` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/hdfs` | new |
| `hdfs-characteristics` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/hdfs` | new |
| `hdfs-high-availability-ha` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/hdfs` | new |
| `highlevel-architecture-1-2-3-4-5` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/hdfs` | new |
| `highlevel-architecture-1-2-3-4` | grokking-the-advanced-system-design-interview | `UNASSIGNED` | unassigned |
| `highlevel-architecture-1-2-3` | grokking-the-advanced-system-design-interview | `UNASSIGNED` | unassigned |
| `highlevel-architecture-1-2` | grokking-the-advanced-system-design-interview | `UNASSIGNED` | unassigned |
| `highlevel-architecture-1` | grokking-the-advanced-system-design-interview | `UNASSIGNED` | unassigned |
| `highlevel-architecture` | grokking-the-advanced-system-design-interview | `UNASSIGNED` | unassigned |
| `how-chubby-works` | grokking-the-advanced-system-design-interview | `03-technologies/coordination/zookeeper` | enrich |
| `introduction-system-design-patterns` | grokking-the-advanced-system-design-interview | `SKIP/meta` | skip/meta |
| `kafka-characteristics` | grokking-the-advanced-system-design-interview | `03-technologies/messaging/kafka` | enrich |
| `kafka-deep-dive` | grokking-the-advanced-system-design-interview | `03-technologies/messaging/kafka` | enrich |
| `kafka-delivery-semantics` | grokking-the-advanced-system-design-interview | `03-technologies/messaging/kafka` | enrich |
| `kafka-introduction` | grokking-the-advanced-system-design-interview | `03-technologies/messaging/kafka` | enrich |
| `kafka-workflow` | grokking-the-advanced-system-design-interview | `03-technologies/messaging/kafka` | enrich |
| `locks-sequencers-and-lockdelays` | grokking-the-advanced-system-design-interview | `03-technologies/coordination/zookeeper` | enrich |
| `master-election-and-chubby-events` | grokking-the-advanced-system-design-interview | `03-technologies/coordination/zookeeper` | enrich |
| `master-operations` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/gfs` | new |
| `messaging-systems-introduction` | grokking-the-advanced-system-design-interview | `01-foundations/messaging-basics` | new |
| `metadata` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/gfs` | new |
| `mock-interview-bigtable` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/bigtable` | new |
| `mock-interview-cassandra` | grokking-the-advanced-system-design-interview | `03-technologies/databases/cassandra` | enrich |
| `mock-interview-chubby` | grokking-the-advanced-system-design-interview | `03-technologies/coordination/zookeeper` | enrich |
| `mock-interview-dynamo` | grokking-the-advanced-system-design-interview | `03-technologies/databases/dynamodb` | enrich |
| `mock-interview-gfs` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/gfs` | new |
| `mock-interview-hdfs` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/hdfs` | new |
| `mock-interview-kafka` | grokking-the-advanced-system-design-interview | `03-technologies/messaging/kafka` | enrich |
| `partitioning-and-highlevel-architecture` | grokking-the-advanced-system-design-interview | `UNASSIGNED` | unassigned |
| `quiz-bigtable` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/bigtable` | new |
| `quiz-cassandra` | grokking-the-advanced-system-design-interview | `03-technologies/databases/cassandra` | enrich |
| `quiz-chubby` | grokking-the-advanced-system-design-interview | `03-technologies/coordination/zookeeper` | enrich |
| `quiz-dynamo` | grokking-the-advanced-system-design-interview | `03-technologies/databases/dynamodb` | enrich |
| `quiz-gfs` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/gfs` | new |
| `quiz-hdfs` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/hdfs` | new |
| `quiz-i` | grokking-the-advanced-system-design-interview | `SKIP/meta` | skip/meta |
| `quiz-ii` | grokking-the-advanced-system-design-interview | `SKIP/meta` | skip/meta |
| `quiz-kafka` | grokking-the-advanced-system-design-interview | `03-technologies/messaging/kafka` | enrich |
| `replication-1` | grokking-the-advanced-system-design-interview | `01-foundations/replication` | new |
| `replication` | grokking-the-advanced-system-design-interview | `01-foundations/replication` | new |
| `role-of-zookeeper` | grokking-the-advanced-system-design-interview | `03-technologies/coordination/zookeeper` | enrich |
| `scaling-chubby` | grokking-the-advanced-system-design-interview | `03-technologies/coordination/zookeeper` | enrich |
| `sessions-and-events` | grokking-the-advanced-system-design-interview | `03-technologies/coordination/zookeeper` | enrich |
| `single-master-and-large-chunk-size` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/gfs` | new |
| `sstable` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/bigtable` | new |
| `summary-bigtable` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/bigtable` | new |
| `summary-cassandra` | grokking-the-advanced-system-design-interview | `03-technologies/databases/cassandra` | enrich |
| `summary-chubby` | grokking-the-advanced-system-design-interview | `03-technologies/coordination/zookeeper` | enrich |
| `summary-dynamo` | grokking-the-advanced-system-design-interview | `03-technologies/databases/dynamodb` | enrich |
| `summary-gfs` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/gfs` | new |
| `summary-hdfs` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/hdfs` | new |
| `summary-kafka` | grokking-the-advanced-system-design-interview | `03-technologies/messaging/kafka` | enrich |
| `system-apis` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/gfs` | new |
| `the-life-of-bigtables-read-write-operations` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/bigtable` | new |
| `the-life-of-dynamos-put-get-operations` | grokking-the-advanced-system-design-interview | `03-technologies/databases/dynamodb` | enrich |
| `tombstones` | grokking-the-advanced-system-design-interview | `03-technologies/databases/cassandra` | enrich |
| `vector-clocks-and-conflicting-data` | grokking-the-advanced-system-design-interview | `02-distributed-primitives/vector-clocks` | new |
| `what-is-this-course-about` | grokking-the-advanced-system-design-interview | `SKIP/meta` | skip/meta |
| `working-with-tablets` | grokking-the-advanced-system-design-interview | `03-technologies/reference-systems/bigtable` | new |
| `activity-diagrams` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/uml-basics` | enrich |
| `class-diagram` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/uml-basics` | enrich |
| `design-a-car-rental-system` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/car-rental` | enrich |
| `design-a-hotel-management-system` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/hotel-management` | enrich |
| `design-a-library-management-system` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/library-management` | enrich |
| `design-a-movie-ticket-booking-system` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/movie-ticket-booking` | enrich |
| `design-a-parking-lot` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/parking-lot` | enrich |
| `design-a-restaurant-management-system` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/restaurant` | enrich |
| `design-amazon-online-shopping-system` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/amazon-shopping` | enrich |
| `design-an-airline-management-system` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/airline-management` | enrich |
| `design-an-atm` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/atm` | enrich |
| `design-an-online-stock-brokerage-system` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/online-stock-brokerage` | enrich |
| `design-blackjack-and-a-deck-of-cards` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/blackjack` | enrich |
| `design-chess` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/chess` | enrich |
| `design-cricinfo` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/cricinfo` | enrich |
| `design-facebook-a-social-network` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/facebook` | enrich |
| `design-linkedin` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/linkedin` | enrich |
| `design-stack-overflow` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/stack-overflow` | enrich |
| `objectoriented-basics` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/uml-basics` | enrich |
| `oo-analysis-and-design` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/uml-basics` | enrich |
| `sequence-diagram` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/uml-basics` | enrich |
| `use-case-diagrams` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/uml-basics` | enrich |
| `what-is-uml` | grokking-the-object-oriented-design-interview | `07-object-oriented-design/uml-basics` | enrich |
| `acid-vs-base-properties-in-databases` | grokking-the-system-design-interview | `01-foundations/data-modeling` | enrich |
| `api-gateway-vs-direct-service-exposure` | grokking-the-system-design-interview | `01-foundations/api-design` | enrich |
| `api-gateway-vs-reverse-proxy` | grokking-the-system-design-interview | `01-foundations/api-design` | enrich |
| `batch-processing-vs-stream-processing` | grokking-the-system-design-interview | `UNASSIGNED` | unassigned |
| `bloom-filters` | grokking-the-system-design-interview | `01-foundations/bloom-filters` | new |
| `caching` | grokking-the-system-design-interview | `01-foundations/caching` | enrich |
| `cap-theorem` | grokking-the-system-design-interview | `01-foundations/cap-theorem` | enrich |
| `cdn-usage-vs-direct-server-serving` | grokking-the-system-design-interview | `01-foundations/cdn` | new |
| `checksum-new` | grokking-the-system-design-interview | `02-distributed-primitives/checksum` | new |
| `consistent-hashing-new` | grokking-the-system-design-interview | `01-foundations/consistent-hashing` | enrich |
| `data-compression-vs-data-deduplication` | grokking-the-system-design-interview | `UNASSIGNED` | unassigned |
| `data-partitioning` | grokking-the-system-design-interview | `01-foundations/sharding` | enrich |
| `designing-a-url-shortening-service-like-tinyurl` | grokking-the-system-design-interview | `06-system-designs/bitly` | enrich |
| `designing-a-web-crawler` | grokking-the-system-design-interview | `06-system-designs/web-crawler` | enrich |
| `designing-an-api-rate-limiter` | grokking-the-system-design-interview | `06-system-designs/rate-limiter` | enrich |
| `designing-dropbox` | grokking-the-system-design-interview | `06-system-designs/dropbox` | enrich |
| `designing-facebook-messenger` | grokking-the-system-design-interview | `06-system-designs/whatsapp` | enrich |
| `designing-facebooks-newsfeed` | grokking-the-system-design-interview | `06-system-designs/fb-news-feed` | enrich |
| `designing-instagram` | grokking-the-system-design-interview | `06-system-designs/instagram` | enrich |
| `designing-pastebin` | grokking-the-system-design-interview | `06-system-designs/bitly` | enrich |
| `designing-ticketmaster` | grokking-the-system-design-interview | `06-system-designs/ticketmaster` | enrich |
| `designing-twitter-search` | grokking-the-system-design-interview | `06-system-designs/fb-post-search` | enrich |
| `designing-twitter` | grokking-the-system-design-interview | `06-system-designs/fb-post-search` | enrich |
| `designing-typeahead-suggestion` | grokking-the-system-design-interview | `06-system-designs/typeahead-autocomplete` | new |
| `designing-uber-backend` | grokking-the-system-design-interview | `06-system-designs/uber` | enrich |
| `designing-yelp-or-nearby-friends` | grokking-the-system-design-interview | `06-system-designs/yelp` | enrich |
| `designing-youtube-or-netflix` | grokking-the-system-design-interview | `06-system-designs/youtube` | enrich |
| `functional-vs-nonfunctional-requirements` | grokking-the-system-design-interview | `SKIP/meta` | skip/meta |
| `heartbeat-new` | grokking-the-system-design-interview | `02-distributed-primitives/heartbeat` | new |
| `hybrid-cloud-storage-vs-allcloud-storage` | grokking-the-system-design-interview | `UNASSIGNED` | unassigned |
| `importance-of-discussing-tradeoffs` | grokking-the-system-design-interview | `SKIP/meta` | skip/meta |
| `indexes` | grokking-the-system-design-interview | `01-foundations/data-modeling` | enrich |
| `key-characteristics-of-distributed-systems` | grokking-the-system-design-interview | `SKIP/meta` | skip/meta |
| `latency-vs-throughput` | grokking-the-system-design-interview | `01-foundations/numbers-to-know` | enrich |
| `leader-and-follower-new` | grokking-the-system-design-interview | `01-foundations/replication` | new |
| `load-balancer-vs-api-gateway` | grokking-the-system-design-interview | `01-foundations/load-balancing` | new |
| `load-balancing-algorithms` | grokking-the-system-design-interview | `01-foundations/load-balancing` | new |
| `load-balancing` | grokking-the-system-design-interview | `01-foundations/load-balancing` | new |
| `longpolling-vs-websockets-vs-serversent-events` | grokking-the-system-design-interview | `04-patterns/real-time-updates` | enrich |
| `pacelc-theorem-new` | grokking-the-system-design-interview | `01-foundations/cap-theorem` | enrich |
| `polling-vs-longpolling-vs-webhooks` | grokking-the-system-design-interview | `04-patterns/real-time-updates` | enrich |
| `primaryreplica-vs-peertopeer-replication` | grokking-the-system-design-interview | `01-foundations/replication` | new |
| `proxies` | grokking-the-system-design-interview | `01-foundations/networking-essentials` | enrich |
| `proxy-vs-reverse-proxy` | grokking-the-system-design-interview | `01-foundations/networking-essentials` | enrich |
| `quiz` | grokking-the-system-design-interview | `SKIP/meta` | skip/meta |
| `quorum-new` | grokking-the-system-design-interview | `01-foundations/replication` | new |
| `read-heavy-vs-write-heavy-system` | grokking-the-system-design-interview | `04-patterns/scaling-reads` | enrich |
| `readthrough-vs-writethrough-cache` | grokking-the-system-design-interview | `01-foundations/caching` | enrich |
| `redundancy-and-replication` | grokking-the-system-design-interview | `01-foundations/replication` | new |
| `rest-vs-rpc` | grokking-the-system-design-interview | `01-foundations/api-design` | enrich |
| `serverless-architecture-vs-traditional-serverbased` | grokking-the-system-design-interview | `UNASSIGNED` | unassigned |
| `serverside-caching-vs-clientside-caching` | grokking-the-system-design-interview | `01-foundations/caching` | enrich |
| `sql-vs-nosql-1` | grokking-the-system-design-interview | `01-foundations/data-modeling` | enrich |
| `sql-vs-nosql` | grokking-the-system-design-interview | `01-foundations/data-modeling` | enrich |
| `stateful-vs-stateless-architecture` | grokking-the-system-design-interview | `UNASSIGNED` | unassigned |
| `strong-vs-eventual-consistency` | grokking-the-system-design-interview | `01-foundations/cap-theorem` | enrich |
| `system-design-basics` | grokking-the-system-design-interview | `SKIP/meta` | skip/meta |
| `system-design-interviews-a-step-by-step-guide` | grokking-the-system-design-interview | `SKIP/meta` | skip/meta |
| `system-design-master-template` | grokking-the-system-design-interview | `SKIP/meta` | skip/meta |
| `things-to-avoid-during-system-design-interview` | grokking-the-system-design-interview | `SKIP/meta` | skip/meta |
| `token-bucket-vs-leaky-bucket` | grokking-the-system-design-interview | `06-system-designs/rate-limiter` | enrich |
| `what-are-backoftheenvelope-estimations` | grokking-the-system-design-interview | `01-foundations/numbers-to-know` | enrich |
| `what-is-a-system-design-interview` | grokking-the-system-design-interview | `SKIP/meta` | skip/meta |
| `6943ab6677063849d7ec3733 — *Design Google Ads*` | system-design-interview-crash-course | `06-system-designs/ad-click-aggregator` | enrich |
| `6943ab87368df96ed76edf35 — *Design Stripe Payment Gateway*` | system-design-interview-crash-course | `06-system-designs/payment-system` | enrich |
| `6943aba2eb7a4d6fa49c42e8 — *Design Google Docs*` | system-design-interview-crash-course | `06-system-designs/google-docs` | enrich |
| `69444a9ce4092f77ed73eadf — *Design Amazon S3*` | system-design-interview-crash-course | `06-system-designs/s3` | new |
| `69444aaf444d0494b7366140 — *Design Twitter Timeline*` | system-design-interview-crash-course | `06-system-designs/fb-news-feed` | enrich |
| `69444b86a565e7abd4231903 — *Design Amazon Lambda*` | system-design-interview-crash-course | `06-system-designs/amazon-lambda` | new |
| `6945783f4e4ddd18faf08d17 — *Users who discover content and watch videos.*` | system-design-interview-crash-course | `06-system-designs/netflix` | new |
| `6945ac95716135e82b1744d4 — *We are designing a global online marketplace that connects*` | system-design-interview-crash-course | `06-system-designs/airbnb` | new |
| `6945b7f0d82e4a9c39a896b1 — *Design Google Search*` | system-design-interview-crash-course | `06-system-designs/google-search` | new |
| `6948052cc35010a6cc20b162 — *100 Million+ Daily Active Users (DAU), split into Free and Plus (Paid) tiers.*` | system-design-interview-crash-course | `06-system-designs/chatgpt` | new |
| `69480903853d222b88ec9a10 — *Design Stock Exchange*` | system-design-interview-crash-course | `06-system-designs/stock-exchange` | new |
| `6949abf9d5c46f6c243b8b1d — *Here is the system design for*` | system-design-interview-crash-course | `UNASSIGNED` | unassigned |
| `6949ac567c4334fbab1661c6 — *Design a Distributed Cache (like Redis)*` | system-design-interview-crash-course | `06-system-designs/distributed-cache` | enrich |
| `6949ac6d12526d454709c9ac — *Design a Key-Value Store (like DynamoDB)*` | system-design-interview-crash-course | `06-system-designs/key-value-store` | new |
| `6949acb8c6f7bbe9ec207e11 — *Design WhatsApp*` | system-design-interview-crash-course | `06-system-designs/whatsapp` | enrich |
| `6949accf12526d454709e31c — *Join servers, chat in text channels, and see real-time presence (who is online).*` | system-design-interview-crash-course | `06-system-designs/discord` | new |
| `6949ad3ac6f7bbe9ec20838e — *Design a Distributed Rate Limiter*` | system-design-interview-crash-course | `06-system-designs/rate-limiter` | enrich |
| `6949ad569e786057b26267c2 — *Design a Metrics & Monitoring System (like Datadog/Prometheus)*` | system-design-interview-crash-course | `06-system-designs/metrics-monitoring` | enrich |
| `6949ad757c4334fbab16895b — *Design Amazon Shopping Cart*` | system-design-interview-crash-course | `06-system-designs/shopping-cart` | new |
| `6949adb09e786057b262829f — *Design Facebook “People You May Know”*` | system-design-interview-crash-course | `06-system-designs/linkedin-connections` | new |
| `6949adc69e786057b2628579 — *Design LinkedIn Connections*` | system-design-interview-crash-course | `06-system-designs/linkedin-connections` | new |
| `6949ae149d4b0fee58749b89 — *Design a Collaborative Whiteboard (Miro)*` | system-design-interview-crash-course | `06-system-designs/collaborative-whiteboard` | new |
| `6949ae2f9e786057b2628bba — *Design an Ad Click Aggregator*` | system-design-interview-crash-course | `06-system-designs/ad-click-aggregator` | enrich |
| `6949ae459e786057b2628ef0 — *Design a Live Comment Streaming Service (Twitch Chat)*` | system-design-interview-crash-course | `06-system-designs/fb-live-comments` | enrich |
| `6949ae5612526d454709fe4a — *Design a Code Deployment System*` | system-design-interview-crash-course | `06-system-designs/code-deployment` | new |
| `6949ae6ad5c46f6c243bd24f — *Design an API Gateway*` | system-design-interview-crash-course | `05-microservices/api-gateway` | new |
| `6949aebf9d4b0fee5874a44f — *Design Uber/Lyft*` | system-design-interview-crash-course | `06-system-designs/uber` | enrich |
| `6949af57c75bc82e6c4739d5 — *Design Typeahead/Autocomplete*` | system-design-interview-crash-course | `06-system-designs/typeahead-autocomplete` | new |
| `6949af90c75bc82e6c473d65 — *Design a Distributed Lock Manager (like Chubby)*` | system-design-interview-crash-course | `06-system-designs/distributed-lock-manager` | new |
| `6949afa57c4334fbab16d05b — *Design a Distributed Job Scheduler (like Cron)*` | system-design-interview-crash-course | `06-system-designs/job-scheduler` | enrich |
| `694e4c92259d4ac528dd8670 — *Course Overview*` | system-design-interview-crash-course | `UNASSIGNED` | unassigned |
| `694e4cada035c6c2e3d06e67 — *Who this Course Is for*` | system-design-interview-crash-course | `UNASSIGNED` | unassigned |
| `694e52ccb0931b3b43f6c3ae — *Instead, remember the*` | system-design-interview-crash-course | `UNASSIGNED` | unassigned |
| `694e54bb3f6509cc80336f44 — *How to Cover the Lessons*` | system-design-interview-crash-course | `UNASSIGNED` | unassigned |
