# Lease

> Part of `02-distributed-primitives/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Learning objectives

- Distinguish a lease from a lock (time-bounded ownership).
- Understand lease-based leader election and why it needs clock assumptions.

## Concepts covered

- Lease duration & renewal
- Lease-based leadership
- Clock drift considerations

## Setup

```bash
cd 02-distributed-primitives/lease
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_lock_without_expiry.ipynb`](./notebooks/01_lock_without_expiry.ipynb) — a holder crashing locks everyone out forever.
- [`notebooks/02_time_bounded_lease.ipynb`](./notebooks/02_time_bounded_lease.ipynb) — leases with TTL and renewal; auto-recovery from crashes.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
