# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (review pass)
- NB1: the capacity numbers contradicted the requirements and each other. The stated
  NFR was "hundreds of millions of queries/day" while the cell hard-coded 100k QPS
  (= 8.6 B/day); prose said "~500 TB" index while the code printed 698 TB. QPS is now
  derived from searches/day, and the cell also computes replicas per shard, total
  serving machines (shards × replicas), and crawl ingress for a given recrawl budget.
- NB1: added commentary on the tail-at-scale consequence of 1,400-way fan-out and on
  freshness being a bandwidth bill.
- NB2: TF-IDF and BM25 produced *identical* rankings on the toy corpus, so the "watch
  the results sharpen" claim was unsupported. Added a keyword-stuffed SEO spam document;
  TF-IDF now ranks it #1 and BM25 demotes it to #3, both asserted. Added the honest
  limits of BM25 (purely lexical; per-shard `avg_len` makes scores only approximately
  comparable).
- NB3: the crawler frontier demo printed `fetching: None` six times out of eight because
  the politeness gap never elapsed. It now loops until the frontier drains, shows the
  two hosts interleaving, counts worker stalls, and asserts the duplicate URL was
  deduped — plus the O(queue) cost of the linear scan.
- NB3: the BM25 × PageRank blend used raw features on incomparable scales, so `alpha`
  had almost no effect and the "BM25-heavy" row was in fact PageRank-dominated. Added
  the naive version as an explicit anti-pattern followed by a min-max normalized blend
  where alpha=1.0 and alpha=0.0 provably reach the two pure orderings.

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
