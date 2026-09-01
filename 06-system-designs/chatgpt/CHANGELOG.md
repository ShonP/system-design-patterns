# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20
- Added three runnable notebooks and `pyproject.toml`; rewrote `README.md` to describe what
  the lab now contains.
  - N1 — Requirements & Architecture: FRs/NFRs for an LLM chat product; a fully runnable
    capacity model (demand → tokens → GPUs → KV memory → storage → cost) with every input a
    named assumption and a sanity check at each step; quadratic prompt growth over a
    conversation; prefill/decode GPU split; KV bytes per token and per active conversation;
    a sweep showing where compute stops binding and KV memory starts; cost per million
    tokens cross-checked against subscription revenue.
  - N2 — Serving & Scaling: decode/prefill cost model derived from arithmetic intensity and
    the accelerator ridge point; naive → static batching → continuous batching simulated for
    throughput ceiling, TTFT and p95; the `max_tokens` ↔ batch-size ↔ throughput coupling;
    padding waste under a heavy-tailed output distribution; SSE framing with sequence ids and
    heartbeats; proxy idle timeouts and replica drain time; admission control showing a
    bounded queue out-serving an unbounded one; KV budget vs throughput ceiling; and
    `reserve_max` vs optimistic-with-preemption vs oracle reservation policies.
  - N3 — Conversation State & Reliability: wide-column conversation schema; context-window
    strategies (truncate / summarise / retrieve / hybrid) scored on planted facts plus a
    global-coverage query retrieval cannot answer; weighted-token metering with
    reserve-then-refund; idempotency and resume for a partially-delivered stream, including
    continue-from-prefix after a replica crash; exact-match, prefix/KV and semantic caching
    with a demonstration of semantic caching returning the opposite of the right answer;
    moderation hold-back window vs TTFT.
- Pure Python, stdlib only at runtime — no Docker, no services, no network. All simulations
  are seeded and verified deterministic across repeat runs; all three notebooks execute
  end to end with `uv sync` alone.

## 2026-04-18
- Scaffolded `Chatgpt` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
