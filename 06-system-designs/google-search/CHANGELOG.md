# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Expanded all three notebooks with runnable code and a clear **bad → best** progression:
  - `01_*`: added capacity-estimation cell and an end-to-end toy search (crawl → index → query).
  - `02_*`: added full retrieval progression (linear scan → inverted index → TF-IDF → **BM25**),
    a tokenization pipeline (lowercase, stop-words, stemming), a positional index for phrase
    queries, and snippet generation.
  - `03_*`: added URL canonicalization, a tiny Bloom-filter dedup, `robots.txt` respect,
    combined BM25 × PageRank scoring, a document-sharded query simulation (fan-out + top-K
    merge), and LRU caching for hot queries.
- Updated README concept list to reflect the new content.

## 2026-04-18
- Scaffolded `Google Search` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
