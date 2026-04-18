# Distributed Lock Manager

> Part of the `06-system-designs/` series. Includes runnable notebooks and references.

## Overview

Mutual exclusion across services: leases, fencing tokens, and why TTL alone isn't enough.

## Concepts covered

- Lease-based locks with TTL
- Fencing tokens against GC pauses
- Redis NX+PX approach and its pitfalls
- Consensus-based alternatives (ZK/etcd)

## Setup

```bash
cd 06-system-designs/distributed-lock-manager
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_requirements_and_architecture.ipynb`](./notebooks/01_requirements_and_architecture.ipynb) — Requirements & Architecture
- [`notebooks/02_data_and_api.ipynb`](./notebooks/02_data_and_api.ipynb) — Data Model & APIs
- [`notebooks/03_deep_dive.ipynb`](./notebooks/03_deep_dive.ipynb) — Deep Dive: Toy lock manager with fencing

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
