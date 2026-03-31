# Web Crawler System Design

A hands-on system design exercise where we build a web crawler step by step — designed to extract text data from the web to train an LLM.

---

## Understanding the Problem

A web crawler automatically traverses the web by downloading pages and following links. Our goal: extract text data from 10 billion web pages to train a large language model (like GPT, Gemini, or LLaMA).

---

## Functional Requirements

### In Scope

| # | Requirement |
|---|-------------|
| 1 | **Crawl the web** starting from a given set of seed URLs |
| 2 | **Extract text data** from each web page and store it for later processing |

### Out of Scope

- Actual processing of text data (LLM training)
- Non-text data (images, videos)
- Dynamic content (JavaScript-rendered pages)
- Authentication (login-required pages)

> It's not possible to scrape the entire internet. We aim to crawl the vast majority of the web — many small sites in dark corners will be unreachable.

---

## Non-Functional Requirements

**Scale:** 10 billion pages, avg 2MB per page, must complete in under 5 days.

### In Scope

| # | Requirement | Details |
|---|-------------|---------|
| 1 | **Fault tolerance** | Handle failures gracefully, resume without losing progress |
| 2 | **Politeness** | Respect `robots.txt`, don't overload servers |
| 3 | **Efficiency** | Crawl 10B pages in under 5 days |
| 4 | **Scalability** | Handle 10B pages with distributed crawling |

### Out of Scope

- Security, cost optimization, legal compliance

---

## System Interface

```
Input:  Seed URLs (list of starting URLs)
Output: Extracted text data stored in blob storage (S3)
```

---

## Data Flow

```
1. Take URL from frontier queue
2. Resolve domain → IP via DNS
3. Fetch HTML from external server
4. Extract text data from HTML → store in S3
5. Extract linked URLs from HTML → add to frontier queue
6. Repeat 1-5 until all URLs crawled
```

---

## High-Level Design

```
                    ┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
                    │  Our System                                        │
                    │                                                    │
Seed URLs ──>  ┌────────────────┐      ┌───────────┐                    │
               │ Frontier Queue │─────>│  Crawler   │                   │
               │ (Kafka/SQS)    │<─────│  Workers   │                   │
               └────────────────┘      └─────┬─────┘                    │
                  new URLs added             │                          │
                  back to queue              │ fetch HTML               │
                    │                        v                          │
                    │              ┌──────────────────┐                 │
                    │              │   DNS Resolver    │                 │
                    │              └──────────────────┘                 │
                    │                        │                          │
                    │              ┌─────────v────────┐                 │
                    │              │  External Web    │  ← outside     │
                    │              │  Servers         │    our system   │
                    │              └──────────────────┘                 │
                    │                        │                          │
                    │              ┌─────────v────────┐                 │
                    │              │  S3 Text Data    │                 │
                    │              │  (extracted text) │                 │
                    │              └──────────────────┘                 │
                    └─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
```

**Components:**
- **Frontier Queue** — URLs to crawl (Kafka, Redis, or SQS). Starts with seed URLs, grows as we discover links.
- **Crawler Workers** — Fetch pages, extract text, discover new URLs. Scale horizontally.
- **DNS Resolver** — Resolves domains to IPs. Caching and failure handling are important at scale.
- **S3 Text Data** — Blob storage for extracted text. Cheap, durable, scalable.

---

## Deep Dives

### Deep Dive 1: Fault Tolerance — Pipeline Stages + Retry

**Problem:** The crawler does too much in one step (DNS → fetch → extract text → extract URLs). If any step fails, all progress is lost.

**Solution — Break into pipelined stages:**

```
┌────────────────┐     ┌──────────────────┐     ┌────────────────────────┐
│ Frontier Queue │────>│  URL Fetcher     │────>│ Text & URL Extraction  │
│ (SQS)         │     │  Workers         │     │ Workers                │
│               │     │                  │     │                        │
│ seed URLs +   │     │ fetch HTML →     │     │ extract text → S3      │
│ discovered    │     │ store in S3      │     │ extract URLs → frontier│
└────────────────┘     └──────────────────┘     └────────────────────────┘
                              │                           │
                              v                           v
                       ┌──────────────┐           ┌──────────────┐
                       │  S3 Raw HTML │           │ S3 Text Data │
                       └──────────────┘           └──────────────┘
                              │                           │
                              v                           v
                       ┌──────────────────────────────────────┐
                       │  Metadata DB (DynamoDB/PostgreSQL)   │
                       │  url_id | url | html_s3 | text_s3   │
                       └──────────────────────────────────────┘
```

**Why pipeline?**
- If fetching fails, retry just the fetch — don't re-extract
- If extraction logic changes (e.g., include alt text), re-process stored HTML without re-fetching
- Scale each stage independently (fetchers are I/O bound, extractors are CPU bound)

**Handling fetch failures — SQS visibility timeout + exponential backoff:**

```
Attempt 1: fetch → fails → ChangeMessageVisibility(timeout=30s)
Attempt 2: fetch → fails → ChangeMessageVisibility(timeout=120s)
Attempt 3: fetch → fails → ChangeMessageVisibility(timeout=480s)
...
Attempt 5: fetch → fails → message moves to Dead Letter Queue (DLQ)
                            Site considered offline.
```

**Queue technology choice — SQS** because:
- Built-in visibility timeout (message stays hidden while processing, reappears on failure)
- `ChangeMessageVisibility` API for exponential backoff
- `maxReceiveCount` + DLQ for permanent failures
- Managed scaling, no operational overhead

### Deep Dive 2: Politeness — robots.txt + Domain Rate Limiting

**Problem:** We can't just blast websites with requests. We need to respect `robots.txt` rules (which pages to skip, crawl delay) and limit to ~1 request/sec per domain.

**Two requirements:**

| Requirement | How |
|-------------|-----|
| **Respect robots.txt** | Download + parse `robots.txt` per domain. Check `Disallow` and `Crawl-delay` before each fetch. |
| **Rate limit per domain** | Max 1 request/sec per domain across all crawler workers. |

**robots.txt handling:**

```
robots.txt for example.com:
  User-agent: *
  Disallow: /private/
  Crawl-delay: 10

Crawler pulls URL: example.com/private/page1
  → Check Metadata DB → Disallowed! → ACK message, skip.

Crawler pulls URL: example.com/public/page2
  → Check Crawl-delay → last crawl was 3s ago, delay is 10s
  → ChangeMessageVisibility(timeout=7s) → defer, try later.

Crawler pulls URL: example.com/public/page2 (7s later)
  → Crawl-delay satisfied → acquire domain lock → fetch → update last_crawl_time.
```

**Domain rate limiting with Redis + jitter:**

```
┌──────────────┐
│ Crawler A    │──┐
│ Crawler B    │──┼── check Redis: SET domain:example.com NX EX 1
│ Crawler C    │──┘   (atomic lock, 1 second TTL)
               │
               ├── Lock acquired? → Fetch the page ✅
               └── Lock exists?   → Wait (1s + random jitter) → retry
```

- **Redis `SET NX EX 1`** — atomic per-domain lock with 1-second TTL. Only one crawler can fetch from a domain per second.
- **Jitter** — random 0-500ms delay prevents all crawlers from retrying at the exact same time (thundering herd).
- **Crawl-delay override** — if `robots.txt` says `Crawl-delay: 10`, use 10s TTL instead of 1s.

**Additional state in Metadata DB:**

```
domains table:
  domain | robots_txt | crawl_delay | last_crawl_time
```

### Deep Dive 3: Scaling to 10B Pages in Under 5 Days

**The math:**

```
10B pages × 2MB avg = 20 PB total data
Network-optimized instance: ~200 Gbps → ~12,500 pages/sec theoretical
At ~30% utilization (latency, DNS, politeness): ~3,750 pages/sec per machine

Single machine: 10B / 3,750 = ~2.67M seconds ≈ 30.9 days
8 machines:     30.9 / 8 ≈ 3.9 days ✅ (under 5-day requirement)
```

> We can crawl millions of domains in parallel — rate limit is 1 req/s *per domain*, but across all domains the aggregate throughput is thousands/sec.

**Parser workers:** scale dynamically (Lambda, ECS/Fargate) based on processing queue depth. No need to pre-calculate — just auto-scale.

**DNS — the hidden bottleneck:**

Early crawler research found DNS lookups = 70% of elapsed time per thread. At 1000s of req/sec across millions of domains, DNS is a real bottleneck.

| Optimization | How |
|-------------|-----|
| **DNS caching** | Cache lookups in crawlers — all URLs to the same domain reuse one resolution |
| **Multiple DNS providers** | Round-robin across providers — distribute load, avoid rate limits |

### Deep Dive 4: Efficiency — Deduplication + Crawler Traps

**URL-level dedup:** Before adding a URL to the queue, check if it already exists in the Metadata DB. Skip if already crawled.

**Content-level dedup:** Different URLs can serve identical content (`http://example.com` vs `http://www.example.com`). Hash the page content after fetching and compare.

| Approach | How | Trade-off |
|----------|-----|-----------|
| **DB index on content hash** ✅ | Store `content_hash` in URL table, index it. Check before parsing. | Simple, practical. Modern DB indexes handle billions of rows efficiently. |
| **Bloom filter (Redis)** | Probabilistic set — `BF.ADD` / `BF.EXISTS`. O(1) lookup. | Cool but overkill. False positives mean we might skip a page we haven't seen. Acceptable trade-off at scale. |

> The DB index approach is simpler and more practical. Bloom filters are fun to discuss but rarely necessary with modern databases.

**Crawler traps:** Pages that link to themselves or generate infinite URL variations.

**Fix:** Track **link depth** (hops from seed URL). Seed = depth 0, linked page = depth 1, etc. Stop crawling at depth 15-20. Add `depth` field to URL table.

---

## Final Architecture

```
┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
│  Our System                                                              │
│                                                                          │
│  Seed URLs        ┌──────────────┐                                       │
│  ──────────────> │ Frontier     │                                       │
│                   │ Queue (SQS)  │──── URL dedup check ──> Metadata DB   │
│                   └──────┬───────┘                         (DynamoDB)    │
│                          │                                  │            │
│              ┌───────────v────────────┐    robots.txt       │            │
│              │  URL Fetcher Workers   │◄───check + ─────────┤            │
│              │  (8 machines,          │    domain lock       │            │
│              │   ~3,750 pages/s each) │──> Redis             │            │
│              └───────────┬────────────┘    (rate limit       │            │
│                          │                 per domain)       │            │
│                 ┌────────v─────────┐                         │            │
│                 │   DNS Resolver   │◄── cache + multi-provider           │
│                 └────────┬─────────┘                         │            │
│                          │ fetch HTML                        │            │
│                          v                                   │            │
│  ┌──────────┐   save ┌──────────────┐                        │            │
│  │ External │◄──────│  S3 Raw HTML  │                        │            │
│  │ Web      │        └──────┬───────┘                        │            │
│  └──────────┘               │                                │            │
│                    ┌────────v──────────┐                      │            │
│                    │ Processing Queue  │                      │            │
│                    │ (SQS)             │                      │            │
│                    └────────┬──────────┘                      │            │
│                             │                                │            │
│                    ┌────────v──────────┐   content hash       │            │
│                    │ Parser Workers    │──dedup check──────> │            │
│                    │ (auto-scaling)    │                      │            │
│                    └────────┬──────────┘                      │            │
│                             │                                             │
│                    ┌────────v──────────┐   new URLs                       │
│                    │  S3 Text Data     │──────────────> Frontier Queue    │
│                    └──────────────────┘                                   │
│                                                                          │
│  DLQ: failed fetches after 5 retries (site considered offline)           │
└─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
```

---

## Additional Deep Dives (Bonus)

| Topic | Key Idea |
|-------|----------|
| **Dynamic content** | Use headless browser (Puppeteer/Playwright) to render JS-heavy pages before extraction |
| **Health monitoring** | Datadog/New Relic to track crawler throughput, queue depth, error rates, alerting |
| **Large files** | Send HTTP `HEAD` request first — check `Content-Length`, skip files > 10MB |
| **Continual updates** | Add a **URL Scheduler** that re-queues URLs based on last crawl time, popularity, freshness needs |
| **Priority crawling** | Multiple SQS queues per priority level — crawlers poll high-priority first |

---

## Labs

Hands-on notebooks that walk through each design decision with working code.

| # | Notebook | Topic |
|---|----------|-------|
| 1 | `01_basic_crawler.ipynb` | Basic BFS crawler — fetch, extract text, discover links |
| 2 | `02_fault_tolerance.ipynb` | Pipeline stages, retry with exponential backoff, DLQ |
| 3 | `03_politeness.ipynb` | robots.txt parsing, Redis domain locks, jitter |
| 4 | `04_efficiency.ipynb` | URL + content deduplication, crawler trap prevention |
