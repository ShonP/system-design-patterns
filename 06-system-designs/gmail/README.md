# Gmail

> Part of the `06-system-designs/` series. Includes runnable notebooks and references.

## Overview

Web email at scale: SMTP/IMAP, mailbox storage, threading, and full-text search.

## Concepts covered

- SMTP send/receive protocol
- Message / thread / label data model
- Threading: subject normalization → RFC 5322 headers → full `References` walk with a
  participant-gated subject fallback
- Per-user inverted search index (benchmarked against a linear scan on the same query)
- Capacity estimation: storage growth, index size, and peak read QPS
- Hot/warm/cold storage tiers, attachment content-hash dedup

## Setup

```bash
cd 06-system-designs/gmail
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_requirements_and_architecture.ipynb`](./notebooks/01_requirements_and_architecture.ipynb) — Requirements & Architecture
- [`notebooks/02_data_and_api.ipynb`](./notebooks/02_data_and_api.ipynb) — Data Model & APIs
- [`notebooks/03_deep_dive.ipynb`](./notebooks/03_deep_dive.ipynb) — Deep Dive: SMTP, Search, Storage tiers

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
