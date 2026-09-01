# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18 (QA review)
- Notebook 1: added an L4 vs L7 explainer cell.
- Notebook 2: simulator now records every per-request latency; replaced the
  misleading `stats()` (which previously labelled "P95" but returned a per-
  backend average) with real avg/p50/p95/p99 percentiles. Added the
  **power-of-two-choices** algorithm (capacity-weighted) and updated the chart
  to show avg vs p95.
- Notebook 3: switched `StickyLB` from Python's process-randomized `hash()`
  to a deterministic `hashlib.md5` so the sticky mapping survives restarts.
- Notebook 4 **(new)**: consistent hashing — naive `hash % N` failure demo,
  hash ring with virtual nodes, remap-rate comparison, vnode tuning.
- README: refreshed intro, added Notebook 4 to the table.

## 2026-04-18
- Scaffolded `Load Balancing` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-08-20 (correctness audit)
- NB2: **the simulator had no queueing.** Each backend started every request
  immediately at full speed, so a "busy" backend cost nothing and latency depended
  only on which backend a request landed on — which meant the notebook could not
  actually demonstrate what least-connections is for. Backends are now
  single-worker FIFO queues, so latency = wait + service, and the arrival rate is
  documented (~35% fleet utilisation) so tail latency is attributable to routing
  rather than overload. Round robin's p99 goes from 17 s to 94 s against 15 s for
  the capacity-aware algorithms.
- NB2: asserted the weighted round-robin distribution is exactly 40/40/10/10;
  asserted least-connections does not degenerate into round robin; gave
  least-connections a random tie-break (a deterministic one sent everything to the
  first backend and looked like a spectacular result).
- NB2 **(new)**: weighted least-connections, plus a section explaining why every
  capacity-aware algorithm bottoms out at the same p99 (the floor is
  `largest request / smallest backend`, and none of these algorithms look at the
  request), and a second run at ~80% utilisation where normalising by capacity
  finally pays off.
- NB3: asserted the pool transitions (drained backend gets no traffic, dead backend
  is never called, warm backend rejoins) and that the sticky mapping is stable —
  then showed the three users all move when N goes 3 -> 4, which motivates NB4.
- NB4: added the **server-removal** experiment (only ~1/N of keys move, only keys
  homed on the departed server move, and they spread over all survivors). Asserted
  the ~80% naive remap rate and the ~20% ring remap rate. Fixed a `"%%"` in a chart
  label and made the virtual-node claim honest (the win is 1 -> 50 vnodes; past that
  it is sampling noise).
- Hygiene: kernelspec set to `Python 3 (.venv)` on all four notebooks.
