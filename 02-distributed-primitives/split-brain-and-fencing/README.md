# Split-Brain & Fencing

> Part of `02-distributed-primitives/`. Pure-Python lab — no Docker required.

## Learning objectives

- Explain how network partitions can produce two leaders (split brain).
- Use fencing tokens to make old leaders harmless.

## Concepts covered

- Split-brain scenarios
- Monotonic fencing tokens (and why the check is `<`, not `≤`)
- Fencing vs idempotency — two mechanisms, two jobs (and why the check is `<`, not `≤`)
- Fencing vs idempotency — two mechanisms, two jobs
- STONITH

## Setup

```bash
cd 02-distributed-primitives/split-brain-and-fencing
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_split_brain.ipynb`](./notebooks/01_split_brain.ipynb) — 🟥 **BAD**: partition + slow GC pause = two leaders writing at once. Reproduces the bug with a config store and a bank-balance example.
- [`notebooks/02_fencing_tokens.ipynb`](./notebooks/02_fencing_tokens.ipynb) — 🟧 **BETTER** (in-memory token) → 🟩 **BEST** (token persisted on the resource, `<` check — plus request ids for replay protection, which is a *different* problem). Monotonic tokens let storage reject stale leaders' writes even across restarts.
- [`notebooks/03_stonith_and_resource_fencing.ipynb`](./notebooks/03_stonith_and_resource_fencing.ipynb) — 🔫 When tokens aren't enough: resource fencing (NFS ACL revoke) and STONITH (IPMI power-off). How HDFS HA, Pacemaker and Patroni combine all three layers.

## When you need this — and when you don't

**You need fencing whenever** a "leader" can be wrong about being the leader — which is always,
because no failure detector can tell a crashed node from a paused one. A lock, a lease, and a
health check all leave this hole open; only the *resource* rejecting stale writers closes it.

**The rule is `token < highest_seen → reject`.** Reject-on-equal breaks the current leader, which
must write many times under one token. Deduplicating retries is a separate problem with a separate
tool (idempotency keys) — notebook 2 runs both side by side.

**Escalate only when tokens can't reach.** Resource fencing (revoke the NFS export, rotate the
credential, drop the firewall rule) when you cannot modify the resource; STONITH when a stale node
could do irreversible damage. Tokens first — they are cheap and always correct.

**You don't need any of this when** the shared resource is genuinely idempotent, or when there is
no shared mutable resource at all. Fencing protects state; if two leaders can both run harmlessly,
the cost of getting fencing right is not worth paying.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
