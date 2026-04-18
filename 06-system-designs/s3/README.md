# S3 (Object Storage)

> Part of `06-system-designs/`. Runnable notebooks + references.

## Overview

Object storage: buckets, versioning, replication, presigned URLs.

## Concepts covered

- Object vs file vs block storage
- Metadata plane vs data plane
- Erasure coding basics
- Versioning with tombstones
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
