# Amazon Lambda (Serverless)

> Part of `06-system-designs/`. Runnable notebooks + references.

## Overview

Serverless compute: cold start, container pooling, event triggers.

## Concepts covered

- Control plane vs data plane split
- Back-of-envelope sizing (QPS, storage, cold-start bandwidth)
- Function registration + immutable versioning with aliases
- Metadata cache on invokers (avoids DB on the hot path)
- Cold start vs warm start (runnable simulation)
- Warm pool with TTL-based eviction
- Concurrency limits per function and per account (throttling with 429)
- Async invocation: queue + exponential backoff + DLQ
- Power-of-two-choices scheduling
- Provisioned concurrency & SnapStart / snapshot restore

## Setup

```bash
cd 06-system-designs/amazon-lambda
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
