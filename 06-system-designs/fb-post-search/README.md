# Facebook Post Search

📖 **Source**: [Hello Interview – Design Facebook's Post Search](https://www.hellointerview.com/learn/system-design/problem-breakdowns/fb-post-search)

## Overview

How does Facebook let you search through **trillions** of posts in under 500ms? The answer lies in **inverted indexes**, **smart ranking algorithms**, and **caching at every layer**.

This lab walks you through the core search concepts hands-on: from understanding why naive SQL `LIKE` queries fail at scale, to building inverted indexes, implementing typeahead autocomplete, and combining relevance with popularity and recency for production-grade ranking.

The system is **write-heavy** (10K posts/sec + 100K likes/sec) and must support 10K searches/sec with < 500ms latency. We'll explore how the architecture handles both sides.

## Requirements

### Functional

| # | Requirement |
|---|-------------|
| 1 | Search posts by free-text keyword |
| 2 | Sort results by relevance, by recency, or by popularity (likes) |
| 3 | Paginate through results |
| 4 | Typeahead suggestions as the user types |

### Non-Functional

| # | Requirement | Target |
|---|-------------|--------|
| 1 | **Low latency** | < 500 ms median for a search |
| 2 | **Freshness** | a new post is searchable within ~1 minute |
| 3 | **Write throughput** | 10K posts/sec **and** 100K likes/sec must not stall search |
| 4 | **Availability over consistency** | a slightly stale result set is fine; an unavailable search box is not |
| 5 | **Scale** | ~3.6 trillion posts |

### Out of scope

Personalized ranking (which would destroy the cacheability the design depends on),
privacy/ACL filtering per viewer, non-text posts, and multi-language analysis.

---

## Capacity Estimate

Assumptions: **3.6 trillion posts**, **~1 KB per post** including metadata, of which
~300 B is text (~40 words → **~25 unique indexable terms** after stop-word removal).

**Raw corpus**

```
3.6e12 posts x 1 KB = 3.6 PB
```

**Inverted index — the number that actually sizes the cluster**

```
postings = 3.6e12 posts x 25 terms = 9e13 (term, doc) pairs

Lucene delta-encodes doc ids and variable-byte packs them, so a posting
costs roughly 1-2 bytes rather than a full 8-byte doc id.

9e13 x 1.5 B = ~135 TB of primary index
```

So the index is ~4% of the raw corpus. That is the whole reason search is tractable:
**you never touch the 3.6 PB during a query.**

**Shards and nodes**

```
Elasticsearch shards want to stay in the 10-50 GB range (bigger = slow recovery,
slow rebalancing, long GC pauses).

135 TB / 50 GB   = ~2,700 primary shards
x3 (1 primary + 2 replicas) = ~8,100 shards, ~405 TB total
at ~2 TB usable per node    = ~200 nodes
```

**And here is the problem that number creates**

```
10K searches/sec, scatter-gather across 2,700 shards
  = 27,000,000 shard queries/sec
```

That does not work, and no amount of hardware fixes it. A document-partitioned index (which
is what Elasticsearch gives you by default, and what Notebook 1 builds) means every query
must ask every shard, because any shard might hold a match. The fix is one of:

- **Route by time.** The overwhelming majority of searches want recent posts. Put each
  week in its own index and query only the last few. This turns 2,700 shards into a handful
  and is why time-based indices are the standard pattern for post/log search.
- **Term-partitioned index.** Shard by term instead of by document, so a query for "coffee"
  touches exactly one shard. Reads become cheap; writes become horrible, because a single
  new post must update ~25 different shards. Almost nobody does this.

The honest answer is: route by time, accept that "search all of history" is a slow,
rate-limited, different code path from "search recent posts", and cache aggressively.

**Write load**

```
Posts:  10K/sec x 25 terms   = 250K posting updates/sec — fine, batched through Kafka.

Likes:  100K/sec. Naively, 100K index updates/sec — and Lucene has no in-place
        update; changing one field rewrites the whole document (delete + reinsert)
        and leaves a tombstone for the merge process to clean up. This alone would
        cost more than all the post indexing combined.

        The milestone trick: only push the like count to the index at powers of 2
        (1, 2, 4, 8, 16 ...). A post that ends up with L likes causes log2(L)
        index writes instead of L.

        At an average of ~100 likes per post:  7 writes instead of 100
        100K likes/sec x (7/100) = ~7K index writes/sec   — a 14x reduction.
```

The price is that the index's like counts are **wrong between milestones** — which is
precisely why Notebook 3 needs a two-stage architecture that re-ranks candidates against
live counts.

**Read load and cache**

```
10K searches/sec. Query popularity is heavily Zipf-distributed and results are
NOT personalized, so the same query returns the same page for everyone —
the single most cache-friendly property this design has.

At an 80% cache hit rate:  10K x 0.2 = 2K searches/sec actually reach Elasticsearch.
Cache the top ~1M query -> result-page entries at ~10 KB each = ~10 GB of Redis.
```

Note how much rests on "no personalization". Add per-viewer ranking and the cache key
becomes `(query, user)`, the hit rate collapses toward zero, and the 2K/sec becomes 10K/sec
against a 200-node cluster. That is a product decision with a very large infrastructure bill
attached to it.

---

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Full-Text Search Indexing | Inverted indexes, tokenization, PostgreSQL tsvector, Elasticsearch basics |
| 2 | Typeahead and Autocomplete | Prefix tries, edge n-grams, completion suggesters |
| 3 | Search Ranking and Relevance | BM25 scoring, function_score, multi-keyword queries, two-stage architecture |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd 06-system-designs/fb-post-search

# Start PostgreSQL + Elasticsearch + Visualization Tools
docker compose up -d

# Wait ~30s for Elasticsearch to start, then verify:
curl http://localhost:9200/_cluster/health?pretty

# Install dependencies
uv sync

# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8081
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `fb_post_search`
- **Use for**: Explore the posts table, run SQL queries, see query plans

### Kibana (Elasticsearch GUI)
- **URL**: http://localhost:5601
- **First time**: Go to **Dev Tools** (hamburger menu → Management → Dev Tools)
- **Use for**: Run Elasticsearch queries interactively, inspect index mappings, explore scoring

## Key Concepts Covered

### The Search Problem at Scale
- Facebook has **3.6 trillion posts** (~3.6 PB, assuming ~1 KB per post)
- **10K posts created per second**, **100K likes per second**
- Search must return results in **< 500ms**
- New posts must be searchable within **< 1 minute**

### Inverted Indexes
- **Normal index**: Document → words it contains
- **Inverted index**: Word → documents that contain it
- This flips O(n) full-scan search into O(1) dictionary lookup
- PostgreSQL GIN index, Elasticsearch, and Redis all use this concept

### Search Ranking
- **BM25** — improved TF-IDF that considers term frequency, document frequency, and length
- **Function Score** — combine BM25 with popularity (likes) and recency (time decay)
- **Two-Stage Architecture** — fast approximate retrieval → precise re-ranking with fresh data

### Autocomplete & Typeahead
- **Prefix Tries** — tree data structure for O(prefix_length) lookups
- **Edge N-Grams** — pre-compute prefixes at index time for instant search
- **Completion Suggesters** — Elasticsearch's built-in typeahead using FST

### Scaling Strategies (from the design)
- **Caching**: CDN + Redis cache for repeated queries (no personalization = cache-friendly)
- **Write batching**: Aggregate likes over time windows before updating indexes
- **Milestone updates**: Only update like counts at powers of 2 (1, 2, 4, 8...)
- **Hot/cold storage**: Frequently searched terms in Redis, rare terms in blob storage

## Architecture Overview

```
                    ┌──────────────┐
                    │  CDN Cache   │ ← Cache search results at edge
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │ API Gateway  │ ← Auth, rate limiting
                    └──────┬───────┘
                           │
              ┌────────────┴────────────┐
              │                         │
       ┌──────▼──────┐          ┌──────▼──────┐
       │   Search    │          │  Ingestion  │
       │   Service   │          │   Service   │
       └──────┬──────┘          └──────┬──────┘
              │                        │
              │                   ┌────▼────┐
              │                   │  Kafka  │ ← Buffer writes
              │                   └────┬────┘
              │                        │
       ┌──────▼──────────────────▼─────▼──┐
       │     Elasticsearch / Redis        │
       │     (Inverted Indexes)           │
       │  ┌─────────────┐ ┌────────────┐  │
       │  │Creation Idx │ │ Likes Idx  │  │
       │  │(sorted list)│ │(sorted set)│  │
       │  └─────────────┘ └────────────┘  │
       └──────────────────────────────────┘
```

## Real-World Scale

| Metric | Value |
|--------|-------|
| Total posts | ~3.6 trillion (~3.6 PB raw, ~135 TB indexed) |
| Post creation rate | ~10K/sec |
| Like rate | ~100K/sec |
| Search rate | ~10K/sec |
| Latency SLA | < 500ms median |
| Freshness SLA | < 1 min for new posts |

## License

Educational content — feel free to use and modify for learning purposes.
