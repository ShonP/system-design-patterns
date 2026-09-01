# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (repo-wide verification pass)
- **Fix**: all 4 notebooks were pinned to a Jupyter kernel named `sharding` that is not registered anywhere, so they raised `NoSuchKernel` on open. They now use the lab's own `.venv`.
- Corrected the setup path in the README and notebooks (`cd core-concepts/sharding` → `01-foundations/sharding`).
- All 4 notebooks executed end-to-end against the docker-compose stack. The second shard publishes on host port **55433**; run `python tools/check_ports.py` if the stack will not start.
