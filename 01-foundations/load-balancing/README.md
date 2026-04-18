# Load Balancing

> Part of `01-foundations/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

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

## Planned notebooks

> These are planned; files do not yet exist. Following the repo convention, each will be added as a separate numbered notebook (`NN_*.ipynb`) without renumbering earlier ones.

- `notebooks/01_intro_round_robin_vs_least_conn.ipynb`
- `notebooks/02_layer4_vs_layer7.ipynb`
- `notebooks/03_sticky_sessions_tradeoffs.ipynb`
- `notebooks/04_liveness_vs_readiness.ipynb`

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
