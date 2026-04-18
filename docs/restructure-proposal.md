# Repository Restructure Proposal

> Status: **Proposal** — no files have been moved. This document describes the target structure, the current→proposed mapping, how the newly scraped Design Gurus content (503 lessons) maps onto it, and a convention for adding more content incrementally without deleting existing labs.

---

## 1. Goals (from owner)

1. Clean up the repo — some things are misplaced.
2. Make it easy to add new topics (Temporal, Orleans, durability patterns, …).
3. Make it easy to add tech-specific content (new Redis features, new Kafka features, …).
4. New content on an existing topic should **add** to existing labs — never replace.
5. Fit the 503 newly scraped Design Gurus lessons into labs — existing or new.
6. Keep security certification labs separate.
7. Structure must be intuitive and scalable.

---

## 2. Summary of what exists today

| Top-level dir | Labs | Notes |
|---|---|---|
| `core-concepts/` | 8 | api-design, caching, cap-theorem, consistent-hashing, data-modeling, networking-essentials, numbers-to-know, sharding |
| `deep-dives/` | 10 | api-gateway, cassandra, dynamodb, elasticsearch, kafka, postgres, redis, time-series-databases, vector-databases, zookeeper |
| `system-designs/` | 27 | bitly, uber, whatsapp, instagram, youtube, dropbox, rate-limiter, top-k, web-crawler, … |
| `patterns/` | 7 | dealing-with-contention, large-blobs, long-running-tasks, multi-step-processes, real-time-updates, scaling-reads, scaling-writes |
| `enterprise-patterns/` | 5 | azure-authentication, bcdr, gdpr-paired-regions, long-running-jobs-temporal, privacy-review, security-review |
| `security/` | 4 cert tracks | az-500, sc-100, sc-200, sc-900 |
| `scraper/` | – | Node scraper + `content/` (hellointerview) + `designgurus/content/` (new) |

### Scraped content just added

| Course | Lessons |
|---|---|
| grokking-the-system-design-interview | 63 |
| grokking-system-design-fundamentals | 104 |
| grokking-the-advanced-system-design-interview | 117 |
| grokking-system-design-interview-ii | 13 |
| system-design-interview-crash-course | 34 |
| grokking-scalable-systems-for-interviews | 56 |
| grokking-microservices-design-patterns | 93 |
| grokking-the-object-oriented-design-interview | 23 |
| **Total** | **503** |

---

## 3. Problems with today's structure

1. **`patterns/` is ambiguous.** It actually holds *scaling & reliability* patterns. The new microservices scraped content is also "patterns" but very different in nature.
2. **`enterprise-patterns/` mixes** process-level things (privacy review, security review) with workflow/DR patterns (Temporal long-running jobs, BCDR, GDPR regions). Two different audiences.
3. **`deep-dives/api-gateway/` is misplaced** — an API Gateway is a microservices pattern, not a DB/tech deep dive.
4. **Core concepts missing dedicated labs** that are heavily covered in the scraped content: load balancing, CDN, DNS, replication, bloom filters, ID generation, auth, observability, messaging basics.
5. **`scraper/` sits at the top level** like a first-class citizen, but it's a dev tool.
6. **No convention for incremental additions.** When new content arrives about Redis, there is no agreed slot for it — leading to either bloated notebooks or replaced ones.
7. **Object-Oriented Design (OOD/LLD)** has no home at all.

---

## 4. Proposed top-level structure

```
system-design-labs/
├── README.md
├── docs/
│   ├── restructure-proposal.md          (this file)
│   ├── content-map.md                   (scraped-lesson → lab mapping, living doc)
│   └── lab-template/                    (copy-paste skeleton for new labs)
│
├── 01-foundations/                      (renamed from core-concepts; broader)
│   ├── api-design/
│   ├── caching/
│   ├── cap-theorem/
│   ├── consistent-hashing/
│   ├── data-modeling/
│   ├── networking-essentials/
│   ├── numbers-to-know/
│   ├── sharding/
│   ├── load-balancing/                  NEW
│   ├── cdn/                             NEW
│   ├── dns/                             NEW (or stays inside networking-essentials)
│   ├── replication/                     NEW (leader-follower, quorum, sync/async)
│   ├── bloom-filters/                   NEW
│   ├── id-generation/                   NEW (UUID/ULID/KSUID/Snowflake)
│   ├── authentication-authorization/    NEW (OAuth, JWT, sessions, mTLS)
│   ├── messaging-basics/                NEW (queues, pub/sub, delivery semantics)
│   └── observability/                   NEW (OTel, SLI/SLO/SLA, error budgets)
│
├── 02-distributed-primitives/           NEW top-level (from advanced course)
│   ├── write-ahead-log/
│   ├── segmented-log/
│   ├── high-water-mark/
│   ├── lease/
│   ├── heartbeat/
│   ├── gossip-protocol/
│   ├── phi-accrual-failure-detection/
│   ├── split-brain-and-fencing/
│   ├── vector-clocks/
│   ├── merkle-trees/
│   ├── hinted-handoff/
│   ├── read-repair/
│   ├── checksum/
│   └── quorum/
│
├── 03-technologies/                     (renamed from deep-dives)
│   ├── databases/
│   │   ├── postgres/
│   │   ├── cassandra/
│   │   ├── dynamodb/
│   │   ├── redis/
│   │   ├── elasticsearch/
│   │   ├── time-series-databases/
│   │   └── vector-databases/
│   ├── messaging/
│   │   └── kafka/
│   ├── coordination/
│   │   └── zookeeper/
│   ├── reference-systems/               NEW (canonical papers, from advanced course)
│   │   ├── gfs/
│   │   ├── hdfs/
│   │   ├── bigtable/
│   │   ├── dynamo/
│   │   ├── chubby/
│   │   └── s3/
│   └── workflow-engines/                NEW (for Temporal/Orleans to land here)
│       └── temporal/                    (pulled from enterprise-patterns)
│
├── 04-patterns/                         (renamed from patterns/; scope stays "scaling & reliability")
│   ├── scaling-reads/
│   ├── scaling-writes/
│   ├── dealing-with-contention/
│   ├── large-blobs/
│   ├── long-running-tasks/
│   ├── multi-step-processes/
│   ├── real-time-updates/
│   ├── resilience/                      NEW (circuit breaker, retry+backoff, bulkhead)
│   ├── idempotency/                     NEW (keys, exactly-once, replay)
│   ├── outbox-and-cdc/                  NEW
│   └── rate-limiting-and-throttling/    NEW (vs quotas; moved sub-topic from system-designs)
│
├── 05-microservices/                    NEW top-level (from microservices course + api-gateway)
│   ├── api-gateway/                     (moved from deep-dives)
│   ├── bff/
│   ├── service-discovery/
│   ├── sidecar/
│   ├── circuit-breaker/                 (see also 04-patterns/resilience/)
│   ├── bulkhead/
│   ├── retry/
│   ├── saga/
│   ├── cqrs/
│   ├── event-driven-architecture/
│   ├── strangler/
│   └── configuration-externalization/
│
├── 06-system-designs/                   (kept; adds new problems from scraped courses)
│   ├── <existing 27 labs, unchanged paths>
│   └── <new labs — see §6>
│
├── 07-object-oriented-design/           NEW top-level (from OOD course)
│   ├── uml-basics/                      (class/sequence/activity/use-case diagrams)
│   ├── oo-analysis-and-design/
│   ├── parking-lot/
│   ├── hotel-management/
│   ├── library-management/
│   ├── movie-ticket-booking/
│   ├── atm/
│   ├── blackjack/
│   ├── chess/
│   ├── cricinfo/
│   ├── car-rental/
│   ├── restaurant/
│   ├── amazon-shopping/
│   ├── airline-management/
│   ├── online-stock-brokerage/
│   ├── facebook/
│   ├── linkedin/
│   └── stack-overflow/
│
├── 08-enterprise/                       (renamed; slimmer; process-level things)
│   ├── azure-authentication/
│   ├── bcdr/
│   ├── gdpr-paired-regions/
│   ├── privacy-review/
│   └── security-review/
│   # NOTE: long-running-jobs-temporal/ moves to 03-technologies/workflow-engines/temporal/
│
├── security-certs/                      (renamed from security/; separate, as requested)
│   ├── az-500/
│   ├── sc-100/
│   ├── sc-200/
│   └── sc-900/
│
└── tools/
    └── scraper/                         (moved from /scraper/)
        ├── designgurus/                 (scraped content stays here)
        └── hellointerview/
```

### Why the numeric prefixes?

They give an intuitive reading order (foundations → primitives → tech → patterns → services → system designs → OOD → enterprise) without forcing the reader to follow it. They also sort nicely in IDEs and `ls`.

---

## 5. Current → Proposed mapping (file moves, no deletes)

| Current path | Proposed path |
|---|---|
| `core-concepts/*` | `01-foundations/*` (same subfolders) |
| `deep-dives/api-gateway/` | `05-microservices/api-gateway/` |
| `deep-dives/postgres|cassandra|dynamodb|redis|elasticsearch|time-series-databases|vector-databases/` | `03-technologies/databases/<same>/` |
| `deep-dives/kafka/` | `03-technologies/messaging/kafka/` |
| `deep-dives/zookeeper/` | `03-technologies/coordination/zookeeper/` |
| `patterns/*` | `04-patterns/*` (same subfolders) |
| `enterprise-patterns/long-running-jobs-temporal/` | `03-technologies/workflow-engines/temporal/` |
| `enterprise-patterns/{bcdr,gdpr-paired-regions,privacy-review,security-review,azure-authentication}/` | `08-enterprise/<same>/` |
| `system-designs/*` | `06-system-designs/*` (unchanged leaves) |
| `security/*` | `security-certs/*` |
| `scraper/` | `tools/scraper/` |

Everything else (new directories) is additive — no existing lab is deleted or renamed destructively; only the parent folder changes.

---

## 6. Scraped content → labs mapping

Full per-lesson mapping will live in `docs/content-map.md` (to be generated). High-level plan:

### 6a. Lessons that enrich existing labs (ADD content, don't replace)

| Existing lab (proposed path) | Scraped lessons that feed it |
|---|---|
| `01-foundations/caching/` | fundamentals: `introduction-to-caching`, `cache-read-strategies`, `cache-invalidation`, `cache-replacement-policies`, `cache-coherence-and-consistency-models`, `cache-performance-metrics`, `types-of-caching`, `caching-challenges`, `why-is-caching-important`; scalable: `negative-caching`, `soft-vs-hard-ttl`, `distributed-locking-for-cache-rebuilds`, `http-conditional-requests-etag`; interview: `caching`, `readthrough-vs-writethrough-cache`, `serverside-caching-vs-clientside-caching` |
| `01-foundations/cap-theorem/` | `introduction-to-cap-theorem`, `components-of-cap-theorem`, `examples-of-cap-theorem-in-practice`, `beyond-cap-theorem`, `pacelc-theorem-new`, `17-pacelc-theorem`, `16-cap-theorem`, `strong-vs-eventual-consistency` |
| `01-foundations/consistent-hashing/` | `consistent-hashing-new`, `2-consistent-hashing`, scalable: `rendezvous-hashing-vs-consistent-hashing` |
| `01-foundations/sharding/` | `data-partitioning`, `data-sharding-techniques`, `benefits-of-data-partitioning`, `common-problems-associated-with-data-partitioning`, `partitioning-methods`, `database-federation`, scalable: `choose-good-shard-key`, `range-directory-geo-sharding` |
| `01-foundations/networking-essentials/` | `tcp-vs-udp`, `http-10-vs-11-vs-20-vs-30`, `http-vs-https`, `dns-resolution-process`, `dns-load-balancing-and-high-availability`, `proxies`, `proxy-vs-reverse-proxy`, `uses-of-proxies`, `what-is-a-proxy-server`, `vpn-vs-proxy-server`, `url-vs-uri-vs-urn`, scalable: `tcp-udp-quic`, `http-1-2-3-head-of-line`, `forward-reverse-proxy-nat`, `gslb-geodns-anycast` |
| `01-foundations/api-design/` | fundamentals: `rest-vs-rpc`, `xml-vs-json`, `usage-of-api-gateway`, `introduction-to-api-gateway`, `advantages-disadvantages-api-gateway`; scalable: `api-pagination-strategies`, `http-conditional-requests` |
| `01-foundations/data-modeling/` | `sql-vs-nosql`, `sql-vs-nosql-1`, `sql-databases`, `nosql-databases`, `sql-normalization-and-denormalization`, `introduction-to-databases`, `acid-vs-base-properties`, `acid-vs-base-properties-in-databases`, `indexes`, `types-of-indexes`, `what-are-indexes`, `inmemory-database-vs-ondisk-database`, scalable: `sql-isolation-levels`, `mvcc`, `safe-patterns-for-online-schema-changes` |
| `01-foundations/numbers-to-know/` | `latency-vs-throughput`, `what-are-backoftheenvelope-estimations`, `latency-and-performance`, `little's-law`, `back-of-envelope-sizing-qps-bandwidth` |
| `03-technologies/databases/cassandra/` | advanced: `cassandra-introduction`, `cassandra-consistency-levels`, `anatomy-of-cassandras-read-operation`, `anatomy-of-cassandras-write-operation`, `compaction`, `tombstones`, `gossiper`, `mock-interview-cassandra`, `summary-cassandra`, `quiz-cassandra` |
| `03-technologies/databases/dynamodb/` | advanced: `dynamo-introduction`, `dynamo-characteristics-and-criticism`, `the-life-of-dynamos-put-get-operations`, `vector-clocks-and-conflicting-data`, `mock-interview-dynamo`, `summary-dynamo` |
| `03-technologies/messaging/kafka/` | advanced: `kafka-introduction`, `kafka-characteristics`, `kafka-deep-dive`, `kafka-delivery-semantics`, `kafka-workflow`, `consumer-groups`, `controller-broker`, `mock-interview-kafka`, `summary-kafka`; fundamentals: `introduction-to-kafka`, `rabbitmq-vs-kafka-vs-activemq`, `messaging-patterns`, `message-queues-vs-service-bus`, `popular-messaging-queue-systems`; scalable: `delivery-semantics-at-most/least/exactly-once`, `idempotent-producers-consumers`, `message-ordering-partition-keys` |
| `03-technologies/coordination/zookeeper/` | advanced: `chubby-introduction`, `how-chubby-works`, `master-election-and-chubby-events`, `locks-sequencers-and-lockdelays`, `sessions-and-events`, `scaling-chubby`, `mock-interview-chubby`, `summary-chubby`, `role-of-zookeeper` |
| `04-patterns/real-time-updates/` | `longpolling-vs-websockets-vs-serversent-events`, `difference-between-longpolling-websockets-and-serversent-events`, `polling-vs-longpolling-vs-webhooks`, `eventdriven-vs-polling-architecture`, `push-vs-pull-notification-systems` |
| `04-patterns/scaling-writes/` | `write-heavy` lessons, `replication-methods`, `data-replication-vs-data-mirroring`, `what-is-replication`, scalable: `outbox-pattern-cdc` |
| `04-patterns/scaling-reads/` | `read-heavy-vs-write-heavy-system`, scalable: `sync-vs-async-replication-read-replicas` |
| `04-patterns/dealing-with-contention/` | advanced primitives on quorum, vector clocks; scalable: `mvcc`, `sql-isolation-levels`, `conflict-resolution-strategies` |
| `04-patterns/long-running-tasks/` | scalable: `at-most/least/exactly-once`, `circuit-breaker-vs-retry-vs-rate-limit` |
| `04-patterns/multi-step-processes/` | microservices: `saga-pattern-*`, `the-inner-workings-of-the-saga-pattern` |
| `06-system-designs/bitly/` | `designing-a-url-shortening-service-like-tinyurl` + `designing-pastebin` |
| `06-system-designs/web-crawler/` | `designing-a-web-crawler` |
| `06-system-designs/rate-limiter/` | `designing-an-api-rate-limiter`, crash-course: `Design a Distributed Rate Limiter`, `token-bucket-vs-leaky-bucket`, scalable: `rate-limiting-vs-throttling-vs-quotas` |
| `06-system-designs/dropbox/` | `designing-dropbox` |
| `06-system-designs/whatsapp/` | `designing-facebook-messenger`, crash-course: `Design WhatsApp` |
| `06-system-designs/fb-news-feed/` | `designing-facebooks-newsfeed`, crash-course: `Design Twitter Timeline` |
| `06-system-designs/instagram/` | `designing-instagram` |
| `06-system-designs/ticketmaster/` | `designing-ticketmaster` |
| `06-system-designs/fb-post-search/` | `designing-twitter-search`, `designing-typeahead-suggestion` |
| `06-system-designs/uber/` | `designing-uber-backend`, crash-course: `Design Uber/Lyft` |
| `06-system-designs/yelp/` | `designing-yelp-or-nearby-friends` |
| `06-system-designs/youtube/` | `designing-youtube-or-netflix`, crash-course: `Design YouTube` |
| `06-system-designs/payment-system/` | ii: `design-payment-system`, crash-course: `Design Stripe Payment Gateway`, scalable: `idempotency-keys-for-payments` |
| `06-system-designs/leetcode/` | ii: `design-code-judging-system-like-leetcode` |
| `06-system-designs/news-aggregator/` | ii: `design-global-news-aggregator-system-like-google-news` |
| `06-system-designs/ad-click-aggregator/` | crash-course: `Design an Ad Click Aggregator`, `Design Google Ads` |
| `06-system-designs/metrics-monitoring/` | crash-course: `Design a Metrics & Monitoring System` |
| `06-system-designs/job-scheduler/` | crash-course: `Design a Distributed Job Scheduler` |
| `06-system-designs/distributed-cache/` | crash-course: `Design a Distributed Cache` |
| `06-system-designs/google-docs/` | crash-course: `Design Google Docs` |
| `06-system-designs/fb-live-comments/` | crash-course: `Design a Live Comment Streaming Service (Twitch Chat)` |
| `06-system-designs/top-k/` | ii: `youtube-counter` |

### 6b. New labs to create from scraped content

**New under `01-foundations/`:**

- `load-balancing/` — fundamentals: `introduction-to-load-balancing`, `load-balancer-types`, `load-balancing-algorithms`, `stateless-vs-stateful-load-balancing`, `uses-of-load-balancing`, `challenges-of-load-balancers`; interview: `load-balancing`, `load-balancer-vs-api-gateway`; scalable: `sticky-sessions`, `liveness-vs-readiness`
- `cdn/` — fundamentals: `what-is-cdn`, `cdn-architecture`, `push-cdn-vs-pull-cdn`, `origin-server-vs-edge-server`; interview: `cdn-usage-vs-direct-server-serving`
- `replication/` — fundamentals: `what-is-replication`, `replication-methods`, `data-replication-vs-data-mirroring`, `redundancy-and-replication`, `primaryreplica-vs-peertopeer-replication`, `what-is-leader-and-follower-pattern`, `what-is-quorum`; advanced: `3-quorum`, `4-leader-and-follower`, `18-hinted-handoff`, `19-read-repair`; scalable: `sync-vs-async-replication`
- `bloom-filters/` — fundamentals: `introduction-to-bloom-filters`, `applications-of-bloom-filters`, `benefits-limitations-of-bloom-filters`, `variants-and-extensions-of-bloom-filters`; advanced: `1-bloom-filters`; scalable: `how-bloom-filter-reduces-cache-or-db-load`
- `id-generation/` — scalable: `snowflake-style-ids`, `uuid-ulid-ksuid-snowflake`; ii: `design-unique-id-generator`
- `authentication-authorization/` — fundamentals: `authentication-vs-authorization`, `what-is-authentication`, `what-is-authorization`, `oauth-vs-jwt-for-authentication`, `what-is-encryption`; scalable: `tls-vs-mtls`, `server-stored-sessions-vs-jwts`, `secrets-management`; interview: none directly
- `messaging-basics/` — fundamentals: `introduction-to-messaging-system`, `messaging-patterns`, `message-queues-vs-service-bus`, `popular-messaging-queue-systems`, `rabbitmq-vs-kafka-vs-activemq`, `synchronous-vs-asynchronous-communication`; scalable: `message-ordering`
- `observability/` — fundamentals: `monitoring-and-observability`; scalable: `opentelemetry-traces-spans-metrics-logs`, `sli-slo-sla`, `error-budget`, `graceful-degradation-feature-flags`

**New under `02-distributed-primitives/`** (one lab per primitive from the advanced course, lessons `1-bloom-filters` through `20-merkle-trees` + related):
`write-ahead-log`, `segmented-log`, `high-water-mark`, `lease`, `heartbeat`, `gossip-protocol`, `phi-accrual-failure-detection`, `split-brain-and-fencing`, `vector-clocks`, `merkle-trees`, `hinted-handoff`, `read-repair`, `checksum`, `quorum`.

**New under `03-technologies/reference-systems/`** (one lab per canonical paper; each is a `papers/` + notebooks that implement a minimal version):
`gfs`, `hdfs`, `bigtable`, `dynamo`, `chubby`, `s3` (from crash-course `Design Amazon S3`).

**New under `04-patterns/`:**

- `resilience/` — scalable: `circuit-breaker-vs-retry-vs-rate-limit`, `cold-starts-warm-starts`, `graceful-degradation`; microservices: `circuit-breaker-pattern-*`, `bulkhead-pattern-*`, `retry-pattern-*`
- `idempotency/` — scalable: `idempotency-keys-for-payments`, `at-most/least/exactly-once`, `replay-attack`
- `outbox-and-cdc/` — scalable: `outbox-pattern-cdc`
- `rate-limiting-and-throttling/` — scalable: `rate-limiting-vs-throttling-vs-quotas`, `token-bucket-vs-leaky-bucket`

**New under `05-microservices/` (one lab per microservices pattern):**
`api-gateway` (moved), `bff`, `service-discovery`, `sidecar`, `circuit-breaker`, `bulkhead`, `retry`, `saga`, `cqrs`, `event-driven-architecture`, `strangler`, `configuration-externalization`. All sourced from `grokking-microservices-design-patterns/`.

**New under `06-system-designs/`** (problems not yet covered):

| New lab | Source |
|---|---|
| `netflix/` | crash-course: `Design Netflix`; ii: `design-a-recommendation-system-for-netflix` |
| `google-ads/` *(can merge with ad-click-aggregator)* | crash-course |
| `stripe/` *(or payment-system enrichment)* | crash-course |
| `stock-exchange/` | crash-course |
| `discord/` | crash-course |
| `chatgpt/` | crash-course |
| `google-search/` | crash-course |
| `linkedin-connections/` | crash-course: `Design LinkedIn Connections`, `Facebook People You May Know` |
| `s3/` | crash-course: `Design Amazon S3` (also cross-links to `03-technologies/reference-systems/s3/`) |
| `shopping-cart/` | crash-course: `Design Amazon Shopping Cart` |
| `airbnb/` | crash-course |
| `collaborative-whiteboard/` | crash-course: Miro |
| `typeahead-autocomplete/` | crash-course + `designing-typeahead-suggestion` |
| `flash-sale/` | ii: `design-a-flash-sale-for-an-ecommerce-site` |
| `reminder-alert/` | ii |
| `gmail/` | ii |
| `google-calendar/` | ii |
| `reddit/` | ii |
| `notification-system/` | ii: `designing-a-notification-system` |
| `key-value-store/` | crash-course: `Design a Key-Value Store (like DynamoDB)` |
| `distributed-lock-manager/` | crash-course: `Design a Distributed Lock Manager (like Chubby)` |
| `code-deployment/` | crash-course |
| `amazon-lambda/` | crash-course |

**New under `07-object-oriented-design/`:** see structure in §4. All 17 OOD problem labs map 1:1 to files in `grokking-the-object-oriented-design-interview/`, plus `uml-basics/` covers `class-diagram`, `sequence-diagram`, `activity-diagrams`, `use-case-diagrams`, `what-is-uml`, `objectoriented-basics`, `oo-analysis-and-design`.

---

## 7. Per-lab layout (enforced convention)

Every lab (old or new) adopts this skeleton. Unchanged for current labs; formalised for new ones.

```
<lab>/
├── README.md                 # Overview, learning objectives, how to run
├── docker-compose.yml        # Optional, only if infra needed
├── pyproject.toml            # uv-managed deps (per .github/instructions)
├── notebooks/
│   ├── 01_*.ipynb            # Ordered, following bad → better → best
│   ├── 02_*.ipynb
│   └── …
├── db/                       # Optional init SQL
├── references/               # NEW — append-only pointers to source material
│   ├── designgurus.md        # List of scraped lesson slugs that feed this lab
│   ├── hellointerview.md     # Existing source
│   └── papers.md             # Canonical papers (GFS, Dynamo, Chubby, …)
└── CHANGELOG.md              # NEW — append-only log of notebook additions
```

### `references/designgurus.md` example

```
- course: grokking-system-design-fundamentals
  - cache-read-strategies.md     → notebooks/02_read_strategies.ipynb
  - cache-invalidation.md        → notebooks/04_invalidation.ipynb
- course: grokking-scalable-systems-for-interviews
  - negative-caching.md          → notebooks/06_negative_caching.ipynb (ADDED 2026-04)
  - soft-vs-hard-ttl.md          → notebooks/07_soft_hard_ttl.ipynb  (ADDED 2026-04)
```

---

## 8. Convention for **adding** content (never replacing)

Rule of thumb: **new content = new file (notebook or section), not rewritten file.**

1. **New sub-topic inside an existing lab** (e.g. a new Redis Streams feature):
   - Add a new numbered notebook `NN_<topic>.ipynb` at the end of `notebooks/`.
   - Append a row to `references/*.md` and an entry to `CHANGELOG.md`.
   - Do **not** renumber existing notebooks.

2. **New lab entirely** (e.g. Orleans):
   - Copy `docs/lab-template/` into the right section.
   - Register it in the section's README and in `docs/content-map.md`.

3. **Existing topic, expanded depth** (e.g. Redis Cluster deep content):
   - If it's a cohesive 3–5 notebook story, create a **sub-lab** like `03-technologies/databases/redis/advanced/` and link from the parent README. Don't touch the existing notebooks.

4. **New scraped content drop:**
   - Run a mapping pass that produces/updates `docs/content-map.md` (lesson slug → lab → notebook idea).
   - For each row, either append to an existing lab (`CHANGELOG.md` entry) or open a new lab folder.
   - Never overwrite an existing notebook without explicit owner approval.

5. **Durability / new cross-cutting topics (e.g. "durability patterns")** get their own sub-folder under `04-patterns/` (or `02-distributed-primitives/` if they are building blocks). The numeric prefixes let you slot new top-levels in without disturbing anything.

---

## 9. Migration plan (suggested; not executed by this document)

1. **Phase 0** — land this proposal and `docs/content-map.md` generator (no moves).
2. **Phase 1** — introduce new top-levels as empty folders (`02-distributed-primitives/`, `05-microservices/`, `07-object-oriented-design/`, `tools/`) alongside the existing ones.
3. **Phase 2** — `git mv` existing labs into their new homes (`core-concepts` → `01-foundations`, etc.). Update the root `README.md`, `.github/instructions/general.instructions.md`, and any hard-coded paths in notebooks/docker-compose files.
4. **Phase 3** — populate new labs from scraped content one category at a time, starting with the highest-leverage gaps: `bloom-filters`, `load-balancing`, `cdn`, `replication`, the `02-distributed-primitives/*` set, and `05-microservices/*`.
5. **Phase 4** — generate `docs/content-map.md` from `scraper/designgurus/content/` automatically, then hand-curate.

---

## 10. Open questions for the owner

1. Are you happy with the **numeric prefixes** (`01-foundations/` etc.) or would you prefer the old flat names (`core-concepts/`, `technologies/`, …)?
2. `enterprise-patterns/long-running-jobs-temporal/` — move under `03-technologies/workflow-engines/temporal/` (treat Temporal as a technology), or keep it as an enterprise pattern?
3. Some crash-course problems overlap existing labs (`Design Stripe` vs `payment-system/`, `Design Google Ads` vs `ad-click-aggregator/`). Prefer **enriching the existing lab** or **creating a new sibling** for each?
4. OOD: is a dedicated top-level `07-object-oriented-design/` worth it, or should the 17 OOD problems live under `06-system-designs/` with an `ood/` prefix?
5. Do you want `CHANGELOG.md` per lab, or a single repo-wide `CHANGELOG.md`?
