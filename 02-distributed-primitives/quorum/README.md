# Quorum (N, R, W)

> Part of `02-distributed-primitives/`. Pure-Python lab — no Docker required.

## Learning objectives

- Reason about why R + W > N gives strongly consistent reads in a Dynamo-style system.
- Compute the availability/consistency trade-offs of different N/R/W choices.

## Concepts covered

- N, R, W parameters
- Strict vs sloppy quorum
- Consistency/availability trade-offs

## Setup

```bash
cd 02-distributed-primitives/quorum
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

1. [`notebooks/01_quorum_basics.ipynb`](./notebooks/01_quorum_basics.ipynb) —
   bad→best progression: single node → `W=R=1` (stale reads) → `W+R>N`
   (strong consistency). Includes the pigeonhole intuition, an exhaustive
   enumeration of every write-set/read-set pair for `N=5`, and a runnable
   stale read from the near-miss `W=R=2` configuration.
2. [`notebooks/02_tuning_and_tradeoffs.ipynb`](./notebooks/02_tuning_and_tradeoffs.ipynb) —
   availability vs quorum size (binomial model + matplotlib plot) and a small
   tail-latency simulation.
3. [`notebooks/03_sloppy_quorum_and_repair.ipynb`](./notebooks/03_sloppy_quorum_and_repair.ipynb) —
   a strict quorum **failing** first, then Dynamo-style sloppy quorum, hinted
   handoff, read repair, and a note on LWW vs vector clocks vs CRDTs.

## When you need this — and when you don't

**Use quorum reads and writes when** you want tunable consistency without a leader. `W + R > N`
guarantees overlap and therefore a fresh read; anything less trades freshness for latency and
availability, per request.

**Get the inequality right.** It is strict: `W + R > N`, not `≥`. Notebook 1 enumerates every
write-set/read-set pair for `N=5` and then runs the stale read that `W=R=2` permits — a
configuration one short of the rule, which looks fine until it isn't.

**Prefer consensus (Raft/Paxos) when** you need more than fresh single-key reads: compare-and-set,
transactions, or a total order across keys. Quorum overlap gives you the last write for one key
and nothing else.

**Prefer a sloppy quorum when** availability during partial outages matters more than strict
overlap — and accept that you have traded away the `W + R > N` guarantee, along with the
obligation to run hinted handoff and anti-entropy behind it.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
