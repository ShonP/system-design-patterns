# Split-Brain & Fencing

> Part of `02-distributed-primitives/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Learning objectives

- Explain how network partitions can produce two leaders (split brain).
- Use fencing tokens to make old leaders harmless.

## Concepts covered

- Split-brain scenarios
- Monotonic fencing tokens
- STONITH

## Setup

```bash
cd 02-distributed-primitives/split-brain-and-fencing
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_split_brain.ipynb`](./notebooks/01_split_brain.ipynb) — 🟥 **BAD**: partition + slow GC pause = two leaders writing at once. Reproduces the bug with a config store and a bank-balance example.
- [`notebooks/02_fencing_tokens.ipynb`](./notebooks/02_fencing_tokens.ipynb) — 🟧 **BETTER** (in-memory token) → 🟩 **BEST** (token persisted on the resource, `≤` check). Monotonic tokens let storage reject stale leaders' writes even across restarts.
- [`notebooks/03_stonith_and_resource_fencing.ipynb`](./notebooks/03_stonith_and_resource_fencing.ipynb) — 🔫 When tokens aren't enough: resource fencing (NFS ACL revoke) and STONITH (IPMI power-off). How HDFS HA, Pacemaker and Patroni combine all three layers.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
