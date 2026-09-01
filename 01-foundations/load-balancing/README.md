# Load Balancing

> Part of `01-foundations/`. A hands-on, code-first introduction to load balancing. Every concept is demonstrated with a small, self-contained Python simulation — no Docker, no external services.

## Learning objectives

- Understand why load balancers exist and where they sit in a request path.
- Distinguish L4 vs L7 load balancing and the main algorithms (round-robin, least-connections, hashing, random).
- Reason about stateful vs stateless backends and when sticky sessions are necessary vs harmful.
- Design liveness and readiness checks that don't misfire during deploys.

## Concepts covered

- Load balancer types (L4 / L7, hardware / software / cloud)
- Algorithms: round-robin, weighted, least-connections, hashing, random
- Stateful vs stateless backends; sticky sessions / session affinity
- Health checks: liveness vs readiness
- Load balancer vs API gateway vs reverse proxy

## Notebooks in this series

| # | Notebook | What you'll learn |
|---|----------|-------------------|
| 1 | [`01_intro_and_round_robin.ipynb`](./notebooks/01_intro_and_round_robin.ipynb) | What a load balancer is, why one server is a bottleneck, and how round robin fixes it |
| 2 | [`02_algorithms_compared.ipynb`](./notebooks/02_algorithms_compared.ipynb) | Round robin, weighted, least-connections, **weighted** least-connections, random, and **power-of-two-choices** compared on a queueing simulation of an uneven fleet, with real avg/p50/p95/p99 latencies — and why they all share the same p99 floor |
| 3 | [`03_health_checks_and_sticky_sessions.ipynb`](./notebooks/03_health_checks_and_sticky_sessions.ipynb) | Liveness vs. readiness checks, draining an unhealthy backend, and the trade-offs of sticky sessions |
| 4 | [`04_consistent_hashing.ipynb`](./notebooks/04_consistent_hashing.ipynb) | Why naive `hash % N` breaks caches, how a hash ring with virtual nodes fixes it, measured remap rates for **adding and removing** a backend, and where you'll meet this in real systems |

Each notebook is pure Python — backends are simulated in-process, so there is no Docker or external infrastructure to set up for this lab.

## Setup

```bash
# From the repo root
cd 01-foundations/load-balancing

# Install Python dependencies into a local .venv
uv sync
```

### Kernel selection (VS Code)

1. Open any notebook under `notebooks/`.
2. Click the **kernel picker** at the top-right of the notebook.
3. Choose the `.venv` interpreter for this folder.

If the `.venv` kernel doesn't appear:

- Open the command palette: `Cmd+Shift+P` (macOS) or `Ctrl+Shift+P` (Windows/Linux).
- Run **"Developer: Reload Window"** and try again.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
