# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19 (review pass)
- `01_introduction.ipynb`: added a tuning cell on **heartbeat interval vs TTL** with real-world starting points.
- `02_worked_example.ipynb`: added two new sections with runnable examples —
  **load-balancing strategies** (random / round-robin / least-connections / consistent hashing)
  and **graceful shutdown / deregistration on SIGTERM**. Updated the takeaways list to match.
- `03_real_world_patterns.ipynb`: added a **plain DNS as a registry** section (the "step 0"
  option before Kubernetes/Consul) and a **CAP trade-off** section (AP vs CP: Eureka vs
  Consul/etcd/ZooKeeper, plus where Kubernetes sits).
- Re-executed all three notebooks with `jupyter nbconvert --execute` — all cells pass cleanly.

## 2026-04-19
- Rewrote `01_introduction.ipynb` with an explicit bad → better → best progression (hard-coded URLs → plain registry → registry with heartbeats + TTL).
- Expanded `02_worked_example.ipynb` to cover self-registration vs third-party registration, push heartbeats vs pull health checks, and client-side caching for registry outages.
- Added `03_real_world_patterns.ipynb` mapping the pattern onto Kubernetes DNS + Services, HashiCorp Consul, Netflix Eureka, and service meshes (Istio/Linkerd/Envoy), including a runnable Kubernetes-style simulation.
- Updated README concept list and notebook index.
- Verified all three notebooks execute cleanly via `jupyter nbconvert --execute`.

## 2026-04-18
- Scaffolded `Service Discovery` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_introduction.ipynb, 02_worked_example.ipynb.
