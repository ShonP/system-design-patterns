# Dynamo

📄 **Paper**: Giuseppe DeCandia, Deniz Hastorun, Madan Jampani, Gunavardhan Kakulapati,
Avinash Lakshman, Alex Pilchin, Swaminathan Sivasubramanian, Peter Vosshall, and Werner Vogels.
*Dynamo: Amazon's Highly Available Key-value Store*. SOSP '07 — 21st ACM Symposium on Operating
Systems Principles, Stevenson, WA, October 2007.
[Canonical PDF](https://www.allthingsdistributed.com/files/amazon-dynamo-sosp2007.pdf)

> **This is a paper guide, not a runnable lab.** Almost every mechanism in this paper has its own
> hands-on lab elsewhere in the repo — see the cross-links near the bottom.

## What it is, and why it mattered

Dynamo is an internal Amazon key-value store built on one uncomfortable premise: *a write must never
be rejected*. Not during a node failure, not during a network partition, not while a datacentre is
on fire. A customer adding an item to a shopping cart is revenue, and refusing that write is worse
than temporarily disagreeing about what is in the cart. Everything else follows. If you must accept
writes on both sides of a partition, you must tolerate conflicting versions; if you tolerate
conflicting versions, somebody has to resolve them, and Dynamo's answer is that the *application*
does, at read time.

The paper mattered for two reasons. It was the first widely-read production account of choosing
availability over consistency deliberately rather than by accident, and it packaged a set of
techniques — consistent hashing with virtual nodes, sloppy quorums, hinted handoff, Merkle-tree
anti-entropy, gossip membership, vector clocks — into a coherent, copyable whole. That toolkit
became the standard vocabulary of the entire "NoSQL" wave.

## The core design

### 1. Consistent hashing with virtual nodes

```
                       ┌──────────── key k = hash("cart:42") ─────────┐
                       │                                              ▼
                    A ─┴─ B ─── C ─── D ─── E ─── F ─── G ─── A  (ring, wraps)
                            └──────┬──────┘
                        preference list for k, N=3: B, C, D
                        (walk clockwise from k, skipping any position
                         owned by a physical node already in the list;
                         the list extends past N to cover failures)

  Each physical node owns MANY ring positions ("tokens" / virtual nodes), so
  load redistributes to many peers when a node joins or leaves, and a beefier
  machine can simply be given more tokens.
```

### 2. Sloppy quorums, not strict ones

A read needs `R` responses, a write needs `W`, with `R + W > N` as the usual configuration —
`(N, R, W) = (3, 2, 2)` is what most Amazon instances ran. The word that matters is **sloppy**:
operations go to the first `N` *healthy* nodes on the preference list, which are not necessarily
the first `N` nodes on the ring. Availability is preserved during failures, but the overlap
guarantee that `R + W > N` normally implies is not.

### 3. Hinted handoff

If node C is down when a write for it arrives, the write goes to the next healthy node E instead,
tagged with a hint saying "this really belongs to C". E stores it in a separate local area and
periodically tries to deliver it. Durability survives a transient failure without waiting for
recovery.

### 4. Vector clocks and reconciliation at read time

Each version of an object carries a vector clock — a list of `(node, counter)` pairs. Comparing two
clocks tells you whether one descends from the other or whether they diverged. Divergent versions
are *both* kept, and a read returns all causally unrelated versions to the client, which merges
them and writes the result back. The paper's own example is the shopping cart: merge by union.

Clocks are truncated once they exceed a threshold (the paper says "say 10") by dropping the pair
with the oldest timestamp — and the authors note this can make causality detection inaccurate,
while adding that the problem had not surfaced in production and had therefore not been
investigated.

### 5. Anti-entropy with Merkle trees

Each node keeps a Merkle tree per key range it hosts. Two replicas compare root hashes; if they
match, the ranges are identical and nothing is transferred. If not, they descend only into the
subtrees that differ. Divergence is detected and repaired in the background with traffic
proportional to the *difference*, not the data.

### 6. Gossip membership and a zero-hop DHT

Membership and token assignments propagate by gossip; failure detection is local and purely for
the purpose of avoiding communication, not for global agreement. Node addition and removal are
explicit administrator actions, not inferred from failures — deliberately, so a transient outage
never triggers a rebalance. Every node knows the entire ring, so any node can route a request in
one hop; Dynamo refuses multi-hop DHT routing because extra hops inflate tail latency.

### 7. Everything is measured at the 99.9th percentile

The paper's SLAs are of the form "a response within 300 ms for 99.9% of requests at a peak load of
500 requests per second". Averages are explicitly rejected as a target because a page render fans
out to many services and the slowest one sets the user's experience. This framing — design for the
tail, not the mean — is arguably the paper's most widely adopted idea, and it is not a storage idea
at all.

## The key design decisions, and what they cost

| Decision | What it bought | What it gave up |
|---|---|---|
| **Always writeable; resolve conflicts on read** | Writes survive node failure, partitions, and datacentre loss. The paper reports Dynamo returning successful responses for 99.9995% of requests over a year, with no data-loss event. | The conflict burden moves into every application. The canonical failure mode is real and famous: merging shopping-cart versions by union resurrects items the customer deleted. Vector clocks tell you *that* two versions conflict; they never tell you what the right answer is. |
| **Vector clocks for causality** | Precise conflict detection without any coordination, and version size decoupled from update rate. | Clocks grow with the number of coordinating nodes — which sloppy quorums make worse, since writes can be handled by nodes outside the top N. Truncation then makes detection lossy. Later systems mostly moved on: Riak adopted dotted version vectors, Cassandra abandoned the idea entirely for last-write-wins timestamps. |
| **Sloppy quorum + hinted handoff** | High availability for writes during exactly the failures that would break a strict quorum. | `R + W > N` no longer guarantees you read your own write, because the read and write sets may not overlap. This is the single most misunderstood consequence of the paper and it is worth internalising. |
| **Fully decentralised, no master, zero-hop routing** | No coordinator to fail, no scaling bottleneck, and no extra network hop in the tail. | Every node stores full membership, so state grows with cluster size. Membership changes are manual by design, which means an operator is in the loop for scaling. Gossip convergence means brief windows of disagreement. |
| **Optional client-side routing** | Skips the load-balancer hop entirely, and the paper measures a real latency improvement at the 99.9th percentile. | Clients poll a random node roughly every ten seconds for membership, so a client can act on a stale view for that long. |
| **Single-key `get`/`put` on opaque bytes, no isolation** | The simplest possible contract, which is what makes everything else tractable. | No ranges, no secondary indexes, no multi-key atomicity — every access pattern must be encoded into the key. |
| **Write buffering to hit the 99.9th percentile** | A large latency improvement for write-heavy services. | An explicit durability window: buffered writes are lost if the node dies before flushing. The paper mitigates it by having one of the N replicas do a durable write, and is honest that this is a trade, not a free win. |
| **Merkle-tree anti-entropy** | Cheap background repair proportional to divergence. | Trees must be recomputed when key ranges shift, i.e. on every membership change — which is precisely why the paper's later partitioning strategies fix the partitions in place instead of deriving them from node tokens. |

## What it influenced

- **Cassandra inherits the whole distribution layer**: the consistent-hashing ring, virtual nodes,
  replication factor, tunable consistency levels, gossip, hinted handoff, read repair, and
  Merkle-tree anti-entropy. Avinash Lakshman co-authored this paper and went on to co-create
  Cassandra at Facebook, which is why the resemblance is so exact. **Its data model and storage
  engine, however, come from [Bigtable](../bigtable/), not from here** — Cassandra is best
  understood as a Dynamo ring in which every node runs a Bigtable-style LSM engine. It also
  replaced vector clocks with last-write-wins timestamps, deliberately trading conflict fidelity
  for operational simplicity.
- **Riak** is the closest faithful re-implementation, keeping vector clocks and the N/R/W knobs as
  first-class user-facing controls, and later refining them into dotted version vectors.
- **Voldemort** at LinkedIn was another direct descendant.
- **Amazon DynamoDB (2012) is a different system, and conflating the two is a common error.** It
  inherits the name, the tail-latency-first philosophy, and the partition-key model, but it is a
  managed service built on a partitioned, Multi-Paxos-replicated design that offers strongly
  consistent reads and transactions — not sloppy quorums and client-side conflict resolution. The
  real DynamoDB architecture is described in a separate paper: Elhemali et al., *Amazon DynamoDB:
  A Scalable, Predictably Performant, and Fully Managed NoSQL Database Service*, USENIX ATC 2022
  ([PDF](https://www.usenix.org/system/files/atc22-elhemali.pdf)).
- **Beyond storage**: "design to the 99.9th percentile", "every node is identical", and "make the
  failure path the normal path" all propagated far outside key-value stores.

## Where to see these ideas running in this repo

| Idea from the paper | Lab |
|---|---|
| Consistent hashing and virtual nodes | [`01-foundations/consistent-hashing/`](../../../01-foundations/consistent-hashing/) |
| N / R / W and quorum overlap | [`02-distributed-primitives/quorum/`](../../../02-distributed-primitives/quorum/) |
| Vector clocks and concurrent versions | [`02-distributed-primitives/vector-clocks/`](../../../02-distributed-primitives/vector-clocks/) |
| Hinted handoff | [`02-distributed-primitives/hinted-handoff/`](../../../02-distributed-primitives/hinted-handoff/) |
| Read repair | [`02-distributed-primitives/read-repair/`](../../../02-distributed-primitives/read-repair/) |
| Merkle-tree anti-entropy | [`02-distributed-primitives/merkle-trees/`](../../../02-distributed-primitives/merkle-trees/) |
| Gossip membership and failure detection | [`02-distributed-primitives/gossip-protocol/`](../../../02-distributed-primitives/gossip-protocol/) and [`02-distributed-primitives/phi-accrual-failure-detection/`](../../../02-distributed-primitives/phi-accrual-failure-detection/) |
| Replication factor and placement | [`01-foundations/replication/`](../../../01-foundations/replication/) |
| The whole toolkit assembled into a running cluster | [`03-technologies/databases/cassandra/`](../../databases/cassandra/) |
| The managed descendant | [`03-technologies/databases/dynamodb/`](../../databases/dynamodb/) |
| Building one yourself | [`06-system-designs/key-value-store/`](../../../06-system-designs/key-value-store/) |

## Reading guide

**If you have 20 minutes:**

1. **§2.3 Design Considerations** — why conflict resolution moves to reads, and to the application.
2. **Table 1 (in §4)** — the summary table of problem → technique → advantage. It is the whole paper
   on one page and worth memorising.
3. **§4.2–4.4 Partitioning, Replication, Data Versioning** — the ring, the preference list, and
   vector clocks, including the shopping-cart example.
4. **§4.6–4.7 Hinted Handoff and Replica Synchronisation** — sloppy quorums and Merkle trees.

**Then**: **§6 Experiences and Lessons Learned** is the best section in the paper. §6.1 on the
durability/latency trade of write buffering, §6.2 on why the original partitioning scheme was
replaced, and §6.3 on how often divergent versions actually occurred in production are all things
you cannot get from the design sections.

**Skip on a first pass**: §3 Related Work (a survey of 2007-era P2P systems), and §2.2's SLA
discussion can be skimmed once you have the 99.9th-percentile idea.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this guide
- [`../../../docs/restructure-proposal.md`](../../../docs/restructure-proposal.md) — overall repo structure
- [`../../../docs/content-map.md`](../../../docs/content-map.md) — lesson → lab mapping
