# S3 (Object Storage)

> Part of `06-system-designs/`. Runnable notebooks + references.

## Overview

Object storage: buckets, versioning, replication, presigned URLs.

## Concepts covered

- Object vs file vs block storage
- Back-of-envelope for **both planes**: PB/day, peak QPS, and the 365-billion-row
  metadata estimate that actually drives the design
- Metadata plane vs data plane
- Erasure coding basics — with the costs it hides (k-way repair read
  amplification, tail latency across k nodes, small-object overhead)
- **Where "11 nines" comes from**: the naive whole-year model, why it is wrong,
  the repair-window model that replaces it, and why the advertised number is a
  floor set by correlated failure and operator error rather than by disk math
- Versioning with tombstones
- Multipart upload with the rules real S3 enforces (contiguity, 5 MiB minimum,
  ETag verification, idempotent part retry) plus the incomplete-upload bill
- Consistency, runnable: strong read-after-write on `GET` vs eventual `LIST`,
  and why they differ
- **Sharding the metadata plane**: hash vs range partitioning, measured against
  `LIST` cost and write hot-spotting
- Consistent hashing with vnodes, distinct-node placement, and load imbalance measured
- Presigned URLs / HMAC

## Setup

```bash
cd 06-system-designs/s3
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_requirements_and_architecture.ipynb`](./notebooks/01_requirements_and_architecture.ipynb) — Requirements & Architecture
- [`notebooks/02_data_and_api.ipynb`](./notebooks/02_data_and_api.ipynb) — Data Model & APIs
- [`notebooks/03_deep_dive.ipynb`](./notebooks/03_deep_dive.ipynb) — Deep Dive (runnable code)

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
