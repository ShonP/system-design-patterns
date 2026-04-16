# Facebook Post Search

📖 **Source**: [Hello Interview – Design Facebook's Post Search](https://www.hellointerview.com/learn/system-design/problem-breakdowns/fb-post-search)

## Overview

How does Facebook let you search through **trillions** of posts in under 500ms? The answer lies in **inverted indexes**, **smart ranking algorithms**, and **caching at every layer**.

This lab walks you through the core search concepts hands-on: from understanding why naive SQL `LIKE` queries fail at scale, to building inverted indexes, implementing typeahead autocomplete, and combining relevance with popularity and recency for production-grade ranking.

The system is **write-heavy** (10K posts/sec + 100K likes/sec) and must support 10K searches/sec with < 500ms latency. We'll explore how the architecture handles both sides.

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
cd system-designs/fb-post-search

# Start PostgreSQL + Elasticsearch + Visualization Tools
docker-compose up -d

# Wait ~30s for Elasticsearch to start, then verify:
curl http://localhost:9200/_cluster/health?pretty

# Install dependencies
uv sync

# Register Jupyter kernel
uv run python -m ipykernel install --user --name=fb-post-search --display-name="FB Post Search (Python)"

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
- Facebook has **3.6 trillion posts** (~3.6 PB of data)
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
| Total posts | ~3.6 trillion |
| Post creation rate | ~10K/sec |
| Like rate | ~100K/sec |
| Search rate | ~10K/sec |
| Latency SLA | < 500ms median |
| Freshness SLA | < 1 min for new posts |

## License

Educational content — feel free to use and modify for learning purposes.
