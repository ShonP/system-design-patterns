# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Configuration Externalization` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_introduction.ipynb, 02_feature_flags.ipynb.

## 2026-04-19
- Expanded `01_introduction.ipynb` with a BEST step using a typed/validated pydantic `Settings` object and precedence (defaults < file < env).
- Expanded `02_feature_flags.ipynb` with user allow-lists, environment-aware flags, flag-hygiene notes, and a clearer bad→good framing.
- Added `03_config_server.ipynb` — central config server with versioning, hot reload, and graceful degradation when the server is down.
- Added `04_secrets.ipynb` — secrets management: `.env` loading, `Secret`/`SecretStr` wrappers, never-log patterns, survey of real secret stores.
- Added `pydantic>=2.6` to the lab's dependencies.
