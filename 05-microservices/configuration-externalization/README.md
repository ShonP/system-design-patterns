# Configuration Externalization

> Part of the `05-microservices/` series. Includes runnable notebooks and references.

## Overview

Keeping config out of the binary.

## Concepts covered

- Config servers
- Feature flags
- Secret management

## Setup

```bash
cd 05-microservices/configuration-externalization
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_introduction.ipynb`](./notebooks/01_introduction.ipynb) -- Config out of the binary
- [`notebooks/02_feature_flags.ipynb`](./notebooks/02_feature_flags.ipynb) -- Feature flags and environment-based config

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
