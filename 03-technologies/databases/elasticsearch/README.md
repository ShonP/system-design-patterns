# Elasticsearch

📖 **Source**: [Hello Interview – Elasticsearch Deep Dive for System Design Interviews](https://www.hellointerview.com/learn/system-design/03-technologies/databases/elasticsearch)

## Overview

Elasticsearch is a distributed search and analytics engine built on top of Apache Lucene. Whenever a system design problem involves searching, filtering, ranking, or faceting over large datasets, Elasticsearch is the go-to tool.

Think of it like this: a regular database (PostgreSQL) can answer "give me the row with id = 42" really fast, but asking "find all products where the title contains 'wireless' and the price is under $50, sorted by relevance" is where Elasticsearch shines. It was purpose-built for exactly these kinds of queries.

This lab walks you through Elasticsearch from zero — indexing documents, writing search queries, understanding analyzers, running aggregations, and learning how clusters scale — all with runnable Python code.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Indexing and Full-Text Search | Documents, indices, CRUD, `match` vs `term`, bool queries, `search_after` deep pagination |
| 2 | Analyzers and Mappings | Tokenization, custom analyzers, synonyms, keyword vs text, mapping design |
| 3 | Aggregations and Faceted Search | Bucket + metric aggs, cardinality & percentiles, faceted e-commerce search |
| 4 | Scaling Elasticsearch Clusters | Shards, replicas, node types, segments, aliases, index templates, ILM |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- No prior Elasticsearch experience needed!

## Quick Start

```bash
# Navigate to the lab directory
cd 03-technologies/databases/elasticsearch

# Start Elasticsearch + Kibana
docker compose up -d

# Wait for Elasticsearch to be healthy (may take 30–60 seconds)
curl -s http://localhost:9200/_cluster/health | python -m json.tool

# Install dependencies
uv sync

# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Kibana (Elasticsearch GUI)
- **URL**: http://localhost:5601
- **Use for**: Run queries in Dev Tools console, visualize data, explore indices
- **Tip**: Go to **Management → Dev Tools** to get an interactive query console where you can run Elasticsearch queries directly

## Key Concepts Covered

### Basic Concepts
- **Documents** — JSON objects stored in Elasticsearch (like rows in a database)
- **Indices** — Collections of documents (like tables in a database)
- **Mappings** — Schema definitions that tell Elasticsearch how to interpret fields
- **Fields** — Key-value pairs within documents, each with a specific data type

### Search Features
- **Full-Text Search** — Find documents by matching words in text fields
- **`match` vs `term`** — Analyzed full-text search vs exact-match lookups
- **Bool Queries** — Combine multiple conditions with must, should, filter
- **Range Queries** — Filter by numeric or date ranges
- **Nested Queries** — Search within nested objects
- **Deep Pagination** — `search_after` for scaling past the 10,000-result limit

### Analyzers
- **Standard Analyzer** — Default tokenizer + lowercase filter
- **Custom Analyzers** — Build your own text processing pipeline
- **Synonyms** — Make "laptop" also match "notebook computer"
- **Keyword vs Text** — When to use exact match vs full-text search

### Aggregations
- **Bucket Aggregations** — Group documents (like SQL GROUP BY)
- **Metric Aggregations** — Calculate stats (avg, sum, min, max)
- **Cardinality & Percentiles** — Unique-counts (HyperLogLog++) and price distributions
- **Faceted Search** — Build filter panels like Amazon's sidebar

### Cluster Architecture
- **Shards** — Split data across multiple nodes for horizontal scaling
- **Replicas** — Copies of shards for high availability and read throughput
- **Node Types** — Master, Data, Coordinating, Ingest nodes
- **Lucene Segments** — Immutable storage units inside each shard

### Operating Indices
- **Aliases** — Stable names over changing indices → zero-downtime reindexing
- **Index Templates** — Auto-apply mappings/settings to new indices matching a pattern
- **Index Lifecycle Management (ILM)** — Hot → Warm → Cold → Delete phases for time-series data

## Real-World Examples

| System | Why Elasticsearch Matters |
|--------|--------------------------|
| Amazon | Product search across millions of items with filters and facets |
| Uber | Geospatial search to find nearby drivers and restaurants |
| GitHub | Code search across billions of lines of code |
| Netflix | Content search and recommendation filtering |
| Stack Overflow | Full-text search across millions of questions and answers |

## License

Educational content — feel free to use and modify for learning purposes.
