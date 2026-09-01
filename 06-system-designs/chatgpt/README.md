# ChatGPT

> Part of the `06-system-designs/` series. Includes runnable notebooks and references.

## Overview

An LLM-backed chat product: request queueing, GPU batching, token streaming, conversation
state and cost. Pure Python — no GPUs, no model weights, no Docker. Every claim in this lab
is a simulation you can run and change.

## Concepts covered

- **A capacity model where the arithmetic is visible.** Users → conversations → tokens → GPUs
  → KV-cache memory → storage → dollars, every input a named assumption with a plausible
  range, and a human-eyeballable sanity check at each step
- Why prompt work grows **quadratically** with conversation length — the term most
  back-of-envelope answers leave out entirely
- **Prefill vs decode**: derived from arithmetic intensity, not asserted. One is
  compute-bound, one is memory-bandwidth-bound, and only one of them responds to batching
- **Whether compute or KV memory binds** — swept, because with honest assumptions the answer
  flips inside the uncertainty range
- Naive → static batching → **continuous batching**, measured: throughput ceilings, TTFT and
  p95, and the padding waste that a heavy-tailed output distribution inflicts on static batches
- The coupling nobody draws: **the `max_tokens` you advertise sets your batch size**, and
  therefore your throughput and your deploy drain time
- **Streaming** over SSE — sequence ids, heartbeats, and what a long-lived response does to
  idle timeouts, LB retries and rolling deploys
- **Admission control**: a bounded queue that rejects a third of its traffic answers *more*
  users than an unbounded one that rejects nobody
- **KV reservation policies** — `reserve_max` vs optimistic-with-preemption vs an oracle, and
  why the recompute bill is a rounding error while the tail latency is not
- **Context-window strategies compared on what each one loses**: truncation, summarisation,
  retrieval and hybrid, scored against planted facts — including the query class retrieval
  structurally cannot answer
- **Metering in weighted tokens, not requests**, with the reserve-then-refund problem you only
  hit when you cannot know a request's cost until you have already paid it
- **Idempotency and resume for a partially-delivered stream** — the hardest reliability
  problem here, because the model will not reproduce its own output
- **Caching**: exact-match (rare after turn 1), prefix/KV (~70% of prefill, always correct),
  and semantic caching demonstrated returning the *opposite* of the right answer
- **Moderation as a pipeline stage**, and the linear trade between hold-back window and TTFT

## Setup

```bash
cd 06-system-designs/chatgpt
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_requirements_and_architecture.ipynb`](./notebooks/01_requirements_and_architecture.ipynb) — Requirements & Architecture: the runnable capacity model
- [`notebooks/02_serving_and_scaling.ipynb`](./notebooks/02_serving_and_scaling.ipynb) — Serving & Scaling: batching, streaming, load shedding, the KV cache
- [`notebooks/03_conversation_state_and_reliability.ipynb`](./notebooks/03_conversation_state_and_reliability.ipynb) — Conversation State & Reliability: context, quotas, resumable streams, caching, safety

## A note on the numbers

Every hardware and demand figure in this lab is an **assumption with a stated plausible
range**, not a measurement of any real system — tokens/sec per GPU, HBM per accelerator,
conversations per user, summarisation quality. They are chosen to be plausible and internally
consistent, and each conclusion is written so it follows from the *variable* rather than the
value. Where a conclusion is sensitive to an assumption, the notebook sweeps it and shows you
where it flips.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
