# Code Deployment (CI/CD)

> Part of `06-system-designs/`. Runnable notebooks + references.

## Overview

Build, test, deploy, rollback, canary.

## Concepts covered

- Runnable capacity model: Little's Law → concurrent builds → CPU fleet → 90% idle at average
- Pipeline as a DAG (topological sort + parallel execution)
- Artifact immutability & content-addressed storage (why `:latest` is a lie)
- Deploy strategies: big-bang (bad) → rolling → blue/green → canary, with a **failing**
  rollout so you can see a mixed fleet and time a rolling rollback against a blue/green flip
- SLO-gated automatic rollback, and the three-outcome gate that shows how a broken build
  gets promoted to 100% when every step is `inconclusive`
- Separation of build vs deploy, feature flags, forward-compatible migrations

## Setup

```bash
cd 06-system-designs/code-deployment
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_requirements_and_architecture.ipynb`](./notebooks/01_requirements_and_architecture.ipynb) — Requirements, architecture & a bad→best pipeline runner
- [`notebooks/02_data_and_api.ipynb`](./notebooks/02_data_and_api.ipynb) — Data model, APIs & immutable content-addressed artifacts
- [`notebooks/03_deep_dive.ipynb`](./notebooks/03_deep_dive.ipynb) — Rolling / blue-green / canary + SLO-gated auto-rollback

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
