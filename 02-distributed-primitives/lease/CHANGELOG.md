# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Lease` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added `notebooks/01_lock_without_expiry.ipynb` (bad: no expiry).
- Added `notebooks/02_time_bounded_lease.ipynb` (better: TTL + renew).
- Added `notebooks/03_leader_election_auto_renew.ipynb` (real-world: 3 workers, background auto-renewer, simulated crash + failover, fencing token, matplotlib timeline).
- README: expanded learning objectives to cover auto-renewal and fencing tokens.
