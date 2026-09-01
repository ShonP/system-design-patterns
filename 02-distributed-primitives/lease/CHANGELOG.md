# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Lease` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added `notebooks/01_lock_without_expiry.ipynb` (bad: no expiry).
- Added `notebooks/02_time_bounded_lease.ipynb` (better: TTL + renew).
- Added `notebooks/03_leader_election_auto_renew.ipynb` (real-world: 3 workers, background auto-renewer, simulated crash + failover, fencing token, matplotlib timeline).
- README: expanded learning objectives to cover auto-renewal and fencing tokens.

## 2026-08-20
- **Fixed corrupted markdown** in `03_leader_election_auto_renew.ipynb`: every section heading
  was empty and several sentences had fragments relocated to the end of the line.
- Added the clock-skew failure the lab previously only mentioned in a bullet: separate grantor
  and holder clocks, and a measured window in which **two processes both believe they hold the
  lease** — from drift alone, with no crash or partition.
- Added both ways out, run rather than described: a bounded-skew safety margin (shown working at
  20% drift and failing at 50%) and a fencing token (overlap still happens; the stale writer's
  writes are refused).
- Added a zombie-leader demo in notebook 3 whose write is rejected by a fencing check.
