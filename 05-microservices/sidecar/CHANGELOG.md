# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Sidecar` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_introduction.ipynb, 02_worked_example.ipynb.

## 2026-04-19 (later)
- Notebook 01: added "Three classic sidecar variants" (Proxy / Ambassador / Adapter) table and a sidecar-vs-init-container note — common beginner confusion.
- Notebook 02: fixed misaligned ASCII topology diagram (duplicated `:9001` inside the sidecar box); switched to ASCII-only characters so it renders the same everywhere.
- Notebook 03: added "Only retry idempotent requests" note covering safe HTTP methods, transient error classes, retry budgets, and jitter — the missing guard-rail around the retry-proxy demo.
- Re-executed all three notebooks end-to-end to verify they still run cleanly.

## 2026-04-19
- QA pass on notebooks 01 and 02: clarified in-process middleware vs out-of-process sidecar, added "when not to use" guidance, key-properties table, and ASCII topology diagram.
- Made notebook 02 rerun-safe (idempotent server start via `ThreadingHTTPServer`), added timeout + 502 on upstream failure, explained the 127.0.0.1 bind as a bypass-prevention mechanism.
- Added `notebooks/03_real_world_patterns.ipynb`: retry-proxy sidecar with exponential backoff + jitter, log-forwarder sidecar (tail-and-ship), config-refresher sidecar with atomic writes, real-world sidecar inventory (Envoy, linkerd-proxy, Fluent Bit, Vault Agent, OTel Collector), and trade-offs (ambient mesh, startup ordering).
