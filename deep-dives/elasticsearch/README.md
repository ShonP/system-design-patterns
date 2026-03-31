# Elasticsearch

📖 **Source**: [Hello Interview – Elasticsearch Deep Dive for System Design Interviews](https://www.hellointerview.com/learn/system-design/deep-dives/elasticsearch)

## Overview

Elasticsearch is a distributed search and analytics engine built on top of Apache Lucene. Whenever a system design problem involves searching, filtering, ranking, or faceting over large datasets, Elasticsearch is the go-to tool.

Think of it like this: a regular database (PostgreSQL) can answer "give me the row with id = 42" really fast, but asking "find all products where the title contains 'wireless' and the price is under $50, sorted by relevance" is where Elasticsearch shines. It was purpose-built for exactly these kinds of queries.

This lab walks you through Elasticsearch from zero — indexing documents, writing search queries, understanding analyzers, running aggregations, and learning how clusters scale — all with runnable Python code.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Indexing and Full-Text Search | Documents, indices, CRUD operations, match queries, bool queries |
| 2 | Analyzers and Mappings | How text is tokenized, custom analyzers, keyword vs text, mapping design |
| 3 | Aggregations and Faceted Search | Bucket aggregations, metric aggregations, building faceted search like e-commerce filters |
| 4 | Scaling Elasticsearch Clusters | Shards, replicas, node types, cluster architecture, Lucene internals |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- No prior Elasticsearch experience needed!

## Quick Start

```bash
# Navigate to the lab directory
cd deep-dives/elasticsearch

# Start Elasticsearch + Kibana
docker-compose up -d

# Wait for Elasticsearch to be healthy (may take 30–60 seconds)
curl -s http://localhost:9200/_cluster/health | python -m json.tool

# Create virtual environment and install dependencies
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Register Jupyter kernel
python -m ipykernel install --user --name=elasticsearch --display-name="Elasticsearch (Python)"

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
- **Bool Queries** — Combine multiple conditions with must, should, filter
- **Range Queries** — Filter by numeric or date ranges
- **Nested Queries** — Search within nested objects

### Analyzers
- **Standard Analyzer** — Default tokenizer + lowercase filter
- **Custom Analyzers** — Build your own text processing pipeline
- **Keyword vs Text** — When to use exact match vs full-text search

### Aggregations
- **Bucket Aggregations** — Group documents (like SQL GROUP BY)
- **Metric Aggregations** — Calculate stats (avg, sum, min, max)
- **Faceted Search** — Build filter panels like Amazon's sidebar

### Cluster Architecture
- **Shards** — Split data across multiple nodes for horizontal scaling
- **Replicas** — Copies of shards for high availability and read throughput
- **Node Types** — Master, Data, Coordinating, Ingest nodes
- **Lucene Segments** — Immutable storage units inside each shard

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
