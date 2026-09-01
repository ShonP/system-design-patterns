# Hinted Handoff

> Part of `02-distributed-primitives/`. A hands-on walkthrough of how distributed databases (Cassandra, DynamoDB, Riak, ScyllaDB) keep writes from being lost when a replica is briefly unreachable.

## Learning objectives

- Explain, in plain English, how writes survive brief node outages via hints stored on the coordinator.
- Implement a tiny coordinator with a per-target hint queue and last-write-wins timestamps.
- Reason about hint TTL, coordinator crashes, sloppy quorum, and when anti-entropy repair is still required.

## Concepts covered

- Temporary replica substitution
- Hint log (per-target FIFO, timestamped)
- Hint TTL / expiry window **and** a queue size cap (an unbounded buffer in front of a dead node kills the coordinator)
- Coordinator crash as a single point of failure for hints
- Sloppy quorum vs strict quorum
- Relationship with read-repair and Merkle-tree anti-entropy repair

## Setup

```bash
cd 02-distributed-primitives/hinted-handoff
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_writes_lost_when_node_down.ipynb`](./notebooks/01_writes_lost_when_node_down.ipynb) — the **bad** baseline: forward-and-forget silently loses every write a downed replica missed.
- [`notebooks/02_hinted_handoff.ipynb`](./notebooks/02_hinted_handoff.ipynb) — the **good** version: coordinator queues hints and replays them in timestamp order when the replica recovers. Includes a last-write-wins edge case.
- [`notebooks/03_limits_and_sloppy_quorum.ipynb`](./notebooks/03_limits_and_sloppy_quorum.ipynb) — **limits** of hinted handoff: hint TTL, the **size cap** a TTL does not give you, coordinator crashes, sloppy quorum with *distinct* stand-ins, and when you still need anti-entropy repair.

## When you need this — and when you don't

**Use hinted handoff when** you run a leaderless/quorum store and want writes to keep succeeding
through *brief* replica outages — a reboot, a deploy, thirty seconds of packet loss. It is cheap,
targeted, and repairs the recovering node in seconds instead of waiting for the next full sweep.

**Do not use it as your repair mechanism.** It leaks three separate ways, each demonstrated in
notebook 3: hints expire (TTL), hints are capped (memory), and hints die with the coordinator.
Anything that outlives one of those is only fixed by anti-entropy — so hinted handoff sits on top
of repair, it never replaces it.

**Cap it, always.** An unbounded hint queue in front of a node that never comes back turns one
dead replica into a dead coordinator. Both a time bound and a size bound, plus an alert when
either trips.

**Irrelevant when** writes go through consensus: a write a majority has not accepted simply is not
committed, so there is nothing to hand off later.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
