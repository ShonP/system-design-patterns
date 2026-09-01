# Chubby

📄 **Paper**: Mike Burrows. *The Chubby lock service for loosely-coupled distributed systems*.
OSDI '06 — 7th USENIX Symposium on Operating Systems Design and Implementation, Seattle, WA,
November 2006.
[Canonical PDF](https://static.googleusercontent.com/media/research.google.com/en//archive/chubby-osdi06.pdf)

> **This is a paper guide, not a runnable lab.** For a coordination service you can actually start
> and break, go to [`03-technologies/coordination/zookeeper/`](../../coordination/zookeeper/) —
> ZooKeeper is Chubby's open-source descendant and the cross-links below map the concepts across.

## What it is, and why it mattered

Chubby is a service that hands out coarse-grained advisory locks and stores small files, with an
interface that looks like a tiny filesystem. Google's other systems use it to elect a leader and
then advertise who won — [GFS](../gfs/) picks its master with a Chubby lock, and
[Bigtable](../bigtable/) uses it in five separate ways.

The paper's real contribution is an argument, made in its first two pages, that is easy to skip and
worth more than the design that follows. Burrows asks why Google built a *lock service* rather than
shipping a Paxos *library*, and answers honestly: because developers do not plan for high
availability up front, they prototype with one server and bolt on replication later — and a service
can be added late in a way a library cannot. Also, because a system that elects a primary needs
somewhere to *publish* the result, and a lock service that can store small files is already that
place. That reasoning is why every cluster you run today has a ZooKeeper or etcd in it rather than
consensus code linked into each application.

## The core design

### 1. A cell of five replicas, one master

```
┌──────────────────────────────────────────────────────────────────────┐
│  CHUBBY CELL — typically five replicas, in distinct failure domains  │
│                                                                      │
│   replica  replica   ┌──────────────┐  replica  replica              │
│      │        │      │    MASTER    │     │        │                 │
│      └────────┴──────┤ serves ALL   ├─────┴────────┘                 │
│  consensus-replicated│ reads and    │  master lease: a               │
│  log; only the master│ writes       │  majority promise              │
│  writes the database └───────┬──────┘  not to elect another          │
│                                        master for a few seconds      │
└──────────────────────────────┼───────────────────────────────────────┘
                               │
        session + KeepAlive RPCs. The master holds each KeepAlive
        open until the client's lease nearly expires, then extends
        it (12s by default, up to ~60s under load) and piggybacks
        cache invalidations and events onto the reply.
                               │
┌──────────────────────────────┼───────────────────────────────────────┐
│  CLIENT LIBRARY                                                      │
│   • caches file data, metadata and open handles                      │
│   • the cache is kept coherent by master-sent INVALIDATIONS, not     │
│     by expiry — so reads are usually free and never stale            │
│   • events: content changed, child added/removed, master failed      │
│     over, handle invalid, lock acquired, conflicting lock request    │
└──────────────────────────────────────────────────────────────────────┘
```

Replicas elect a master by distributed consensus (Paxos); the master holds a lease that a majority
of replicas periodically renew. Only the master reads and writes the underlying database; the
others copy updates. A typical deployment is one cell per datacentre of several thousand machines.

### 2. A filesystem-shaped namespace

Names look like `/ls/foo/wombat/pouch`. The `ls` prefix stands for *lock service* and is common to
all names; the next component is the cell name, resolved via DNS. Nodes are files or directories,
with no links, and are either **permanent** or **ephemeral** — an ephemeral node disappears when no
client has it open, which makes it a natural liveness indicator. Every node carries ACLs, and reads
and writes are whole-file, because the files are meant to be small.

### 3. Advisory reader/writer locks, plus sequencers

Any file or directory can act as a reader-writer lock. The locks are **advisory**: they conflict
only with other attempts to acquire the same lock, and they do not prevent a client from touching
the underlying resource. To make that safe, a lock holder can request a **sequencer** — an opaque
string containing the lock's name, the mode it was acquired in, and a generation number. The client
passes it along to whatever service the lock protects, and that service checks it and rejects
requests carrying a stale generation. For servers that cannot be modified to check sequencers,
Chubby offers **lock-delay**: after an abnormal lock loss, the lock stays unavailable for a bounded
period.

### 4. Sessions, KeepAlives, jeopardy and the grace period

A client holds a session with the master, maintained by KeepAlive RPCs. The master holds each
KeepAlive open until the client's lease is close to expiring, then returns it and grants an
extension — 12 seconds by default, longer if the master is overloaded and wants fewer round trips.
The same channel delivers cache invalidations and event notifications, so idle sessions are close
to free.

If a client's local lease expires it does not immediately give up. It empties and disables its
cache, enters **jeopardy**, and waits out a **grace period** of 45 seconds by default. If it can
re-establish a session with a new master in that window — new masters honour existing sessions —
the client carries on and never surfaces a failure to the application. This is the mechanism that
lets a Chubby master failover be invisible to applications rather than an outage.

### 5. Consistent client caching

Chubby's caching is invalidation-based, not TTL-based. When file data or metadata is about to
change, the master blocks the modification while it sends invalidations to every client that might
have cached the item, and proceeds only once each client has acknowledged or let its cache lease
lapse. Clients therefore see either fully consistent data or an error — never a stale value. This,
more than the locking, is what made Chubby usable as a name service.

## The key design decisions, and what they cost

| Decision | What it bought | What it gave up |
|---|---|---|
| **A lock service, not a Paxos library** | Availability can be retrofitted onto a system that was prototyped without it, and the election result has a natural place to be published. | Everyone now shares a central dependency, and a Chubby outage becomes an outage of every system built on it. The paper's own measurements show how narrow the margin is: across a sample of cells it recorded 61 outages over 700 cell-days, most of 15 seconds or less and 52 under 30 seconds. Applications survived them only because they were written to expect them. |
| **Coarse-grained locking only** | Locks are held for hours or days, so request volume is tiny, a brief Chubby outage does not disturb existing lock holders, and a modest cell serves thousands of machines. | It is the wrong tool for fine-grained per-object locking, which the paper states explicitly — and clients used it that way anyway. Section 4.5, on abusive clients, exists because of this. |
| **Advisory rather than mandatory locks** | No need to modify the resources being protected; locks stay debuggable and inspectable. | Correctness depends on every participant cooperating. A client that pauses and resumes can act while believing it still holds a lock it lost. Sequencers are the real fix, and they only work if the *downstream* service checks them — which is exactly the fencing-token problem in modern form. |
| **Small files only** | The store is cheap to replicate through consensus and easy to reason about. | Developers stored much larger things, and Google had to add quotas after the fact. |
| **Invalidation-based caching instead of TTLs** | Strong semantics with almost no read traffic reaching the master, which is what made Chubby beat DNS as a name service. | A write must wait for every caching client to acknowledge or expire, so one sick or slow client can stall writers. |
| **Sessions with leases everywhere** | Failures are detected quickly and ephemeral state is cleaned up automatically. | A client that merely *pauses* — GC, CPU starvation, a slow disk — loses its session, its ephemeral files and its locks. The grace period softens this but cannot eliminate it. Every "my ZooKeeper session expired and my leader flapped" incident is this decision. |
| **All reads served by the master** | Trivially linearizable reads. | The master is a throughput ceiling. Proxies and partitioning are described in §3 as the answers, and the paper notes they were designed but not yet in production. |
| **Turned out to be a name service** | Consistent caching gave it far better scaling behaviour than DNS's TTL-based approach, and it displaced DNS for internal use. | The dominant workload was not the one the system was designed around. Section 4.3 is a short lesson in the gap between what you build and what people need. |

## What it influenced

- **ZooKeeper** (Hunt, Konar, Junqueira, Reed — USENIX ATC 2010) is the direct open-source
  descendant, and its *differences* are as instructive as its similarities. It keeps the
  filesystem-shaped namespace, ephemeral nodes, sessions and watches, but it is deliberately **not**
  a lock service: it exposes a wait-free API and lets clients build locks from sequential ephemeral
  znodes. It also serves reads from any replica, accepting stale reads in exchange for read
  scalability — the opposite of Chubby's master-only reads — and offers `sync` for clients that
  need freshness. Chubby's watch-and-cache model was reshaped into ZooKeeper's one-shot watches.
- **etcd** does the same job over Raft with a revision-numbered MVCC key space, leases and watches,
  and is the store underneath Kubernetes. **Consul** is a third take on the same shape.
- **Fencing tokens.** Chubby's sequencer is the origin of the now-standard advice that a distributed
  lock is not safe unless the protected resource validates a monotonically increasing token.
- **HDFS and HBase** both took the Chubby role and filled it with ZooKeeper — HBase uses it exactly
  as Bigtable uses Chubby, and HDFS adopted it for automatic NameNode failover.
- **"Paxos Made Live — An Engineering Perspective"** (Chandra, Griesemer, Redstone, PODC 2007) is
  the companion paper describing how Chubby's replicated log was actually built, and it is the
  better read if you care about implementing consensus rather than consuming it.

## Where to see these ideas running in this repo

| Idea from the paper | Lab |
|---|---|
| Sessions, ephemeral nodes, watches, leader election — the whole model, running | [`03-technologies/coordination/zookeeper/`](../../coordination/zookeeper/) |
| Leases as revocable, time-bounded authority | [`02-distributed-primitives/lease/`](../../../02-distributed-primitives/lease/) |
| Sequencers → fencing tokens, and why a lock alone is not enough | [`02-distributed-primitives/split-brain-and-fencing/`](../../../02-distributed-primitives/split-brain-and-fencing/) |
| Session KeepAlives and liveness detection | [`02-distributed-primitives/heartbeat/`](../../../02-distributed-primitives/heartbeat/) |
| Majority agreement behind master election | [`02-distributed-primitives/quorum/`](../../../02-distributed-primitives/quorum/) |
| Building a lock manager end to end | [`06-system-designs/distributed-lock-manager/`](../../../06-system-designs/distributed-lock-manager/) |
| The two systems that depend on Chubby | [`../gfs/`](../gfs/) and [`../bigtable/`](../bigtable/) |

## Reading guide

**If you have 20 minutes:**

1. **§2.1 Rationale** — the lock-service-versus-library argument. This is the most valuable page in
   the paper and the one most often skipped.
2. **§2.3–2.5 Files, Locks and sequencers, Events** — the API surface, briefly.
3. **§2.7–2.9 Caching, Sessions and KeepAlives, Fail-overs** — the consistency and liveness
   machinery, including the jeopardy/grace-period diagram.
4. **§4 Use, surprises and design errors** — read all of it. §4.3 (use as a name service),
   §4.5 (abusive clients) and §4.6 (lessons learned) are the parts you will remember.

**Skip on a first pass**: §3 Mechanisms for scaling (proxies and partitioning were designed but not
yet deployed when the paper was written), §2.10–2.12 (database, backup, mirroring), and §5
Comparison with related work.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this guide
- [`../../../docs/restructure-proposal.md`](../../../docs/restructure-proposal.md) — overall repo structure
- [`../../../docs/content-map.md`](../../../docs/content-map.md) — lesson → lab mapping
