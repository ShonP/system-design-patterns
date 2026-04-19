# Service Discovery

> Part of the `05-microservices/` series. Includes runnable notebooks and references.

## Overview

Finding healthy service instances at runtime.

## Concepts covered

- The bad → better → best progression: hard-coded URLs → in-memory registry → registry with heartbeats + TTL
- Tuning the heartbeat interval vs TTL
- Client-side vs server-side discovery
- Self-registration vs third-party registration (e.g. Kubernetes/Consul sidecar)
- Push heartbeats vs pull health checks
- Load-balancing strategies: round-robin, random, least-connections, consistent hashing
- Graceful shutdown / deregistration on `SIGTERM`
- Client-side caching to survive registry outages
- Plain DNS as the simplest registry (and why teams outgrow it)
- CAP trade-off for registries: AP (Eureka) vs CP (Consul/etcd/ZooKeeper)
- Real-world systems: Kubernetes DNS + Services, HashiCorp Consul, Netflix Eureka, service meshes (Istio/Linkerd/Envoy)

## Setup

```bash
cd 05-microservices/service-discovery
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` -> **Reload Window**.

## Notebooks

- [`notebooks/01_introduction.ipynb`](./notebooks/01_introduction.ipynb) -- Why discovery: bad (hard-coded URLs) → better (plain registry) → best (registry + heartbeats + TTL)
- [`notebooks/02_worked_example.ipynb`](./notebooks/02_worked_example.ipynb) -- Server-side routing, self-reg vs third-party, push vs pull health checks, client-side caching
- [`notebooks/03_real_world_patterns.ipynb`](./notebooks/03_real_world_patterns.ipynb) -- Kubernetes DNS + Services, Consul, Eureka, service meshes

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
