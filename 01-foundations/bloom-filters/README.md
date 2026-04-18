# Bloom Filters

> Part of `01-foundations/`. A pure-Python lab — no Docker required.

## Learning objectives

- Understand how bloom filters achieve O(1) membership checks with a controllable false-positive rate.
- Implement a minimal bloom filter from scratch (bit array + double hashing).
- Measure false-positive rate vs size and hash count, and compare with the theoretical formula.
- Know when a bloom filter is the right choice (cache/DB miss shielding, duplicate detection).

## Concepts covered

- Bit arrays and multiple hash functions
- False positives vs false negatives (and why the latter is impossible)
- Tradeoff: memory vs false-positive rate, sizing formulas for `m` and `k`
- Counting / scalable bloom filters (briefly)
- Use cases: cache/DB load shielding, set membership, crawler dedup

## Setup

This lab is managed with [`uv`](https://docs.astral.sh/uv/) and uses its own `.venv`.

```bash
cd 01-foundations/bloom-filters
uv sync
```

Then open any notebook in VS Code and select the `.venv` kernel from the kernel picker (top-right of the notebook). If the kernel doesn't show up, reload the window: `Cmd+Shift+P` → **Reload Window**.

There are no external services — everything runs in-process in Python.

## Notebooks

- [`notebooks/01_what_is_a_bloom_filter.ipynb`](./notebooks/01_what_is_a_bloom_filter.ipynb) — build intuition with the *"have I seen this URL before?"* problem. Compare a list, a set, and a bloom filter implemented from scratch.
- [`notebooks/02_false_positive_rates_and_sizing.ipynb`](./notebooks/02_false_positive_rates_and_sizing.ipynb) — the formulas for optimal `m` (bits) and `k` (hashes) given target FPR and expected `n`, verified with a Monte Carlo experiment and a plot.
- [`notebooks/03_applications_cache_and_db.ipynb`](./notebooks/03_applications_cache_and_db.ipynb) — use a bloom filter to shield a slow simulated database from wasted lookups; measure the latency speedup.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
