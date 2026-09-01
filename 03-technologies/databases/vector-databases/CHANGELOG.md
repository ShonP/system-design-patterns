# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (repo-wide verification pass)
- **Fix**: repaired a source line in notebook 1 that had lost its trailing newline, concatenating two statements.
- Corrected the setup path in the README and notebooks after the repo restructure.

## 2026-04-19
- Added **Notebook 4: RAG & Re-Ranking** covering text → vector (hashing trick, no external API), over-fetch + exact rerank, domain-aware rerank, and a minimal RAG retrieval loop.
- Expanded README with **Production Considerations**: updates/deletes, monitoring recall, curse of dimensionality, quantization (scalar / PQ / halfvec), when to graduate from pgvector, and the re-ranking pattern.
- Added a dedicated **RAG pattern** section to the README.
- Added more **real-world examples** (Shopify, YouTube, Duolingo, Stack Overflow).
- Fixed path bug in README and notebooks 1–3 setup cells (`03-technologies/databases/vector-databases` → `03-technologies/databases/vector-databases`).
- Simplified README Quick Start (dropped redundant `ipykernel install` — uv sync + VS Code kernel picker is enough).
- Added cross-reference from Notebook 1 to Notebook 4 for the "how do I get real embeddings?" question.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
