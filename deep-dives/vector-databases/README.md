# Vector Databases

📖 **Source**: [Hello Interview – Vector Databases Deep Dive](https://www.hellointerview.com/learn/system-design/deep-dives/vector-databases)

## Overview

A **vector** (or **embedding**) is an array of numbers that represents something — a sentence, an image, a product, a user. The magic is that **similar things end up with similar vectors**. Vector databases let you find those similar items fast.

Traditional databases are great at exact lookups: "give me user #12345". But ask "find documents similar to this one" and you're in trouble. That's where vector databases come in.

This lab uses **PostgreSQL + pgvector** — a vector extension for Postgres. You don't always need a dedicated vector database. For many use cases, adding pgvector to your existing Postgres is the right starting point.

Each notebook follows a **BAD → BETTER → BEST** progression: we start with the naive approach, show why it breaks, then build up to the proper solution.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Embeddings & Similarity Search | What embeddings are, distance metrics, BAD linear scan → BETTER IVFFlat → BEST HNSW |
| 2 | Vector Indexing Strategies | IVFFlat vs HNSW benchmarks at scale, parameter tuning, recall vs speed tradeoffs |
| 3 | Hybrid Search | Combining vector similarity with traditional filters (price, category, rating) |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd deep-dives/vector-databases

# Start PostgreSQL (with pgvector) + Adminer
docker-compose up -d

# Install dependencies
uv sync

# Register Jupyter kernel
uv run python -m ipykernel install --user --name=vector-databases --display-name="Vector Databases (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8081
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `vector_demo`
- **Use for**: Inspect tables, run queries, explore vector data

## Key Concepts Covered

### What's a Vector?
An array of numbers (typically 128–3072 dimensions) that captures the "meaning" of something. Similar items have similar vectors. A pre-trained model (like OpenAI's embedding API) converts text/images into these vectors.

### Similarity Metrics
- **L2 (Euclidean) distance** `<->` — straight-line distance between two points
- **Cosine distance** `<=>` — angle between two vectors (ignores magnitude)
- **Inner product** `<#>` — dot product (used when vectors are normalized)

### The Nearest Neighbor Problem
Finding the K closest vectors to a query vector. **Exact KNN** checks every vector (slow). **Approximate Nearest Neighbors (ANN)** trades a tiny bit of accuracy for massive speed gains.

### Indexing Strategies
| Index | How It Works | Build Time | Query Speed | Recall |
|-------|-------------|------------|-------------|--------|
| **None** (seq scan) | Check every vector | N/A | Slow (O(n)) | 100% |
| **IVFFlat** | Partition into clusters, search nearby clusters | Fast | Medium | ~90–95% |
| **HNSW** | Navigable small-world graph | Slow | Fast | ~95–99% |

### Hybrid Search
Combine vector similarity with traditional SQL filters (WHERE clauses). Critical for real applications where you need "similar items that are also in stock and under $50".

## Numbers to Know (Interview Reference)

| Metric | Value |
|--------|-------|
| Typical embedding dimensions | 128–3072 |
| OpenAI text-embedding-3-large | 3072 dimensions |
| Storage per vector (128-dim float32) | ~512 bytes |
| Exact KNN on 1M vectors | ~100ms+ |
| HNSW on 1M vectors | ~1–5ms |
| HNSW memory overhead | ~1.5–2× vector data |
| IVFFlat build time (1M vectors) | Seconds |
| HNSW build time (1M vectors) | Minutes |

## Real-World Examples

| System | How Vectors Are Used |
|--------|---------------------|
| Spotify | Song embeddings for "Discover Weekly" recommendations |
| Google Search | Semantic search with document embeddings |
| Amazon | Product embeddings for "Customers also bought" |
| ChatGPT | RAG — retrieve relevant docs via vector search before generating answers |
| Pinterest | Image embeddings for visual similarity search |

## License

Educational content — feel free to use and modify for learning purposes.
