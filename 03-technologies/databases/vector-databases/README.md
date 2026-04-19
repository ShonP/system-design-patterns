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
| 4 | RAG & Re-Ranking | Turning text into embeddings (no external API), retrieve-then-rerank pattern, mini RAG loop |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd 03-technologies/databases/vector-databases

# Start PostgreSQL (with pgvector) + Adminer
docker-compose up -d

# Install dependencies (creates a .venv managed by uv)
uv sync

# Open any notebook in VS Code, then pick the .venv kernel in the
# top-right kernel picker. If it doesn't show up, reload the window
# with Cmd+Shift+P → "Reload Window".
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
| Shopify | Product search & "similar items" using image + text embeddings |
| YouTube | Video recommendations based on watch-history embeddings |
| Duolingo | Grouping learners with similar error patterns |
| Stack Overflow | "Related questions" using question-title embeddings |

## The RAG Pattern (Retrieval-Augmented Generation)

This is the #1 reason vector databases exploded in popularity. LLMs have a knowledge cutoff and can't see your private data. RAG fixes this:

```
User question → embed it → vector search over YOUR docs → top-K chunks
                                                              │
                                                              ▼
                                                    Stuff them into the
                                                    LLM prompt as context
                                                              │
                                                              ▼
                                                    LLM answers grounded
                                                    in YOUR data
```

Vector databases are the "retrieval" in RAG. Notebook 3's hybrid search pattern (keyword + vector + filters) is exactly what production RAG systems use.

## Production Considerations

Things the notebooks don't cover in depth but matter in real systems:

### Updates and Deletes
- **IVFFlat**: Centroids are fixed at build time. Heavy churn → rebuild the index periodically.
- **HNSW**: Supports incremental inserts. Deletes leave "tombstones" — use `VACUUM` to reclaim space.

### Monitoring Recall in Production
- Keep a small labeled ground-truth set. Run it against production daily.
- Alert if recall drops below your threshold (e.g., 95%).
- Recall drifts as data distribution changes — re-tune `ef_search` / `probes` over time.

### Curse of Dimensionality
As dimensions grow, the ratio between nearest and farthest neighbors approaches 1 — "similarity" becomes less meaningful. Mitigations:
- Use **dimensionality reduction** (PCA, UMAP) when you have 3000+ dim vectors and can afford a slight accuracy drop.
- Use models that produce lower-dim embeddings (e.g., `text-embedding-3-small` at 1536 dims instead of 3072).

### Quantization (Shrinking Vectors)
For billions of vectors, even pgvector starts to hurt. Options:
- **Scalar quantization**: Store each float32 (4 bytes) as int8 (1 byte) — 4× storage savings, ~1% recall loss.
- **Product Quantization (PQ)**: Split vector into subvectors, cluster each — 10–100× savings, more recall loss.
- pgvector supports **halfvec** (float16) natively. Dedicated DBs like Milvus/Qdrant support PQ.

### When to Graduate From pgvector

| Situation | Tool |
|-----------|------|
| < 1M vectors, already on Postgres | **pgvector** (this lab) |
| 1M–100M vectors, want managed | **Pinecone**, **Weaviate Cloud** |
| 100M+ vectors, self-host, want PQ | **Milvus**, **Qdrant**, **Vespa** |
| Need hybrid keyword+vector at scale | **Elasticsearch**, **OpenSearch** (with kNN plugin) |

### Re-Ranking Pattern

Production search systems rarely stop at ANN. The common pattern:

```
1. ANN index → fetch top 100 candidates (fast, approximate, recall ~95%)
2. Exact rerank → score those 100 with a slower, more accurate model
3. Return top 10 to the user
```

Why? The slow-but-accurate model (cross-encoder, reranker LLM, business-logic scoring) is too expensive to run on millions of vectors — but fine on 100. Notebook 2 touches this idea; in practice reranking is where most of the quality wins come from.

## License

Educational content — feel free to use and modify for learning purposes.
