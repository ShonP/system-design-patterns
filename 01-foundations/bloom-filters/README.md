# Bloom Filters

> Part of `01-foundations/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Learning objectives

- Understand how bloom filters achieve O(1) membership checks with controllable false-positive rate.
- Implement a minimal bloom filter and measure false-positive rate vs size and hash count.
- Know when a bloom filter is the right choice (cache miss shielding, duplicate detection).

## Concepts covered

- Bit arrays and multiple hash functions
- False positives vs false negatives
- Tradeoff: memory vs false-positive rate
- Counting bloom filters and other variants
- Use cases: cache/db load shielding, set membership

## Planned notebooks

> These are planned; files do not yet exist. Following the repo convention, each will be added as a separate numbered notebook (`NN_*.ipynb`) without renumbering earlier ones.

- `notebooks/01_intro_and_build_a_bloom_filter.ipynb`
- `notebooks/02_false_positive_rate_experiment.ipynb`
- `notebooks/03_bloom_filter_in_front_of_a_cache.ipynb`

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
