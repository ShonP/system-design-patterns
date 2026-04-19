# Configuration Externalization

> Part of the `05-microservices/` series. Includes runnable notebooks and references.

## Overview

Keeping configuration — and secrets — out of the binary so the same
image can run in dev / staging / production, and so operators can change
behaviour without a redeploy.

## Concepts covered

- Hardcoded → env vars → typed/validated `Settings` (pydantic)
- Precedence: defaults < config file < environment
- Feature flags (boolean, % rollout, allow-list, kill-switch)
- Central config server with hot reload and graceful degradation
- Secrets management (`.env`, `SecretStr`, never-log patterns, secret stores)

## Setup

```bash
cd 05-microservices/configuration-externalization
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_introduction.ipynb`](./notebooks/01_introduction.ipynb) — bad → good → best: hardcoded vs env vars vs validated `Settings`, plus `pydantic-settings` `BaseSettings`
- [`notebooks/02_feature_flags.ipynb`](./notebooks/02_feature_flags.ipynb) — feature flags, canary rollouts, attribute targeting, A/B measurement, kill-switches, env-aware flags
- [`notebooks/03_config_server.ipynb`](./notebooks/03_config_server.ipynb) — central config server with versioning, pull + push (watch) hot reload, outage resilience
- [`notebooks/04_secrets.ipynb`](./notebooks/04_secrets.ipynb) — secrets management: `.env`, file mounts, `SecretStr`, rotation, never-log/never-serialise patterns, real secret stores

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
