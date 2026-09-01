# Google File System (GFS)

📄 **Paper**: Sanjay Ghemawat, Howard Gobioff, and Shun-Tak Leung. *The Google File System*.
SOSP '03 — 19th ACM Symposium on Operating Systems Principles, Bolton Landing, NY, October 2003.
[Canonical PDF](https://static.googleusercontent.com/media/research.google.com/en//archive/gfs-sosp2003.pdf)

> **This is a paper guide, not a runnable lab.** GFS is a design document, so the useful artifact
> here is a careful reading of it rather than a simulation. The last section links the labs in this
> repo where its ideas do run as code.

## What it is, and why it mattered

GFS is a distributed file system for storing a few million files that are mostly multi-gigabyte,
on thousands of cheap machines that fail constantly. What made it important was not any single
mechanism — it was the willingness to throw away the POSIX contract. Everyone else in 2003 was
trying to make a cluster filesystem that behaved like a local one. GFS started from an actual
measured workload (crawl and index data, huge sequential reads, huge concurrent appends, almost no
random overwrite) and designed backwards from it: files are append-mostly, the consistency model is
deliberately weak, duplicate records are normal, and applications are expected to cope. That trade
is what let one design serve Google's whole storage tier, and it is the template every scale-out
storage system since has copied — pick the weakest contract your applications can actually live
with, then exploit it hard.

## The core design

### 1. Single master, fat clients, data off the control path

One master holds all metadata: the namespace tree, file → chunk-handle mappings, and the current
locations of every chunk replica. Clients ask the master *where* data lives, cache that answer, and
then talk to chunkservers directly. Bulk data never passes through the master, which is why one
master can serve a cluster of hundreds of machines.

```
                     ┌────────────────────────────────────────────────┐
   1. (filename,     │  MASTER — single; all metadata held in memory  │
      chunk index)   │   • namespace tree + file → chunk handles      │
  ┌─────────────────►│   • chunk handle → replica locations           │
  │  2. chunk handle │   • operation log + periodic checkpoints       │
  │     + replica set│   • leases, re-replication, rebalancing, GC    │
  │◄─────────────────└──────────────────────┬─────────────────────────┘
  │                                         │  HeartBeat: chunkserver state up,
┌─┴──────────┐                              │  instructions back down
│   CLIENT   │        ┌─────────────────────┼─────────────────────┐
│ (library;  │        ▼                     ▼                     ▼
│  caches    │ ┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│  chunk     │ │ chunkserver │       │ chunkserver │       │ chunkserver │
│  locations)│ │   PRIMARY   │       │  secondary  │       │  secondary  │
└─┬──────────┘ │ (60s lease) │       │             │       │             │
  │            └─────────────┘       └─────────────┘       └─────────────┘
  │  3. chunk data ─────►  64 MB chunks stored as plain Linux files,
  └─────────────────────►  three replicas by default
```

### 2. 64 MB chunks with 64-bit handles

Each file is split into fixed-size 64 MB chunks, replicated three times by default. The size is
enormous by filesystem standards and that is the point: it cuts client–master round trips, lets a
client hold one persistent TCP connection to a chunkserver for a long stretch of work, and keeps
the metadata small enough to live in RAM — the master keeps under 64 bytes of metadata per chunk.

### 3. Leases put mutation ordering on a chunkserver, not the master

For each chunk the master grants a *lease* to one replica, which becomes the primary. The primary
assigns serial numbers to all mutations on that chunk and the secondaries apply them in that order.
The initial lease timeout is 60 seconds and extensions ride along on the regular HeartBeat
messages. The master is therefore out of the loop for the entire duration of a write burst.

### 4. Control flow and data flow are decoupled

Data is pushed to the replicas as a *chain*, not a star: the client sends to the nearest
chunkserver, which forwards to the next nearest, pipelined so a machine starts forwarding as soon
as it starts receiving. Control (the "now commit it, in this order" message) goes separately from
client to primary to secondaries. This uses the full outbound bandwidth of every machine and avoids
network bottlenecks that a fan-out from the client would hit.

### 5. Atomic record append

`record append` lets many clients append to the same file concurrently. GFS picks the offset and
guarantees the record lands **at least once** as one contiguous run of bytes. It does not guarantee
identical replicas: if an append fails at one secondary the client retries, so replicas can contain
padding and duplicate records. Applications embed checksums and unique record IDs and filter the
junk out on read. This one primitive replaced most of the distributed locking a producer–consumer
queue would otherwise need.

### 6. A consistency model with three states, not two

A region is **consistent** if all replicas return the same data, **defined** if it is consistent
*and* a reader can see a mutation in its entirety, and **undefined** otherwise. Concurrent
successful writes leave a region consistent but undefined — everyone sees the same mangled mixture
of fragments. Record appends leave defined regions interspersed with inconsistent padding. Chunk
version numbers let the master spot replicas that missed mutations while their server was down;
stale replicas are never handed to clients and get garbage collected.

### 7. Failure handling as routine operations, not exceptions

- **Fast recovery**: master and chunkservers restart in seconds and there is no distinction between
  clean and unclean shutdown.
- **Master state**: the operation log is replicated to multiple machines and checkpointed;
  read-only *shadow* masters serve slightly-stale metadata while the master is down.
- **Data integrity**: each chunkserver breaks a chunk into 64 KB blocks with a 32-bit checksum per
  block, verified before returning any data. Replicas are allowed to differ byte-for-byte, so
  checksums must be per-server, not cross-replica comparisons.
- **Garbage collection is lazy**: a deleted file is renamed to a hidden name and only reclaimed
  after three days (configurable), which makes deletion cheap and accidental deletion recoverable.

## The key design decisions, and what they cost

| Decision | What it bought | What it gave up |
|---|---|---|
| **Single master** | Global knowledge makes placement, re-replication and rebalancing genuinely smart, and the code is dramatically simpler than a distributed metadata service. | Total metadata is bounded by one machine's RAM, so millions-of-small-files workloads are hopeless. The master is a write availability single point; shadow masters are read-only. After a restart the master is "hobbled" for roughly 30–60 seconds while chunkservers report in. **This is the part that aged worst** — Google's successor, Colossus, keeps the chunkservers and shards the metadata layer. |
| **64 MB chunks** | Fewer master round trips, less metadata, long-lived client connections. | Small files occupy one chunk and become hotspots — the paper describes an executable that was read by hundreds of machines at once and had to be worked around by raising its replication factor. |
| **At-least-once record append + weak consistency** | Massive write concurrency with no distributed lock manager. | Every application must be written defensively: checksums, unique record IDs, idempotent processing. You cannot layer a POSIX filesystem on top of this, and you cannot hand it to an unmodified application. |
| **Leases to a primary replica** | The master stays off the hot path even during sustained writes. | After a primary dies the master may have to wait out the lease (up to 60s) before safely granting a new one, unless it can reach the old primary. |
| **No client-side data caching** | No cache coherence problem at all, which matters when clients stream through datasets far larger than memory. | Repeated small reads get no benefit. Clients *do* cache metadata, which can go stale — handled by version numbers and retry, not by invalidation. |
| **Append-optimised** | The dominant workload is fast. | Random overwrites work but are neither fast nor serialisable across concurrent writers. |
| **Custom API (snapshot, record append), not POSIX** | Both features are cheap because the filesystem controls its own contract. Snapshot is copy-on-write on chunks. | No drop-in compatibility; every consumer is a GFS-aware application. |

## What it influenced

- **HDFS** is the closest thing to a direct re-implementation: NameNode ≈ master, DataNode ≈
  chunkserver, block ≈ chunk, same heartbeat/block-report control plane. It deliberately did *not*
  inherit multi-writer record append, choosing a single-writer lease model instead. See
  [`../hdfs/`](../hdfs/).
- **Bigtable** is built directly on GFS — its commit logs and SSTables are GFS files, and the
  "immutable files plus background compaction" pattern only works because GFS makes appends cheap
  and overwrites unnecessary. See [`../bigtable/`](../bigtable/).
- **Chubby** holds the lock that elects the GFS master, one of the first documented cases of a
  storage system outsourcing consensus to a separate coordination service. See
  [`../chubby/`](../chubby/).
- **Colossus**, Google's GFS successor, kept the chunkserver layer and replaced the single master
  with a sharded metadata service stored in Bigtable — an explicit fix for the one limit the paper
  itself flagged.
- **The append-only log as a storage primitive** — Kafka segments, LSM-tree SSTables and
  write-ahead logs all rest on the same observation GFS made first at this scale: sequential
  appends to immutable files are the operation distributed storage can actually make fast.

## Where to see these ideas running in this repo

| Idea from the paper | Lab |
|---|---|
| Leases as time-bounded, revocable authority | [`02-distributed-primitives/lease/`](../../../02-distributed-primitives/lease/) |
| HeartBeat-driven liveness and instruction piggybacking | [`02-distributed-primitives/heartbeat/`](../../../02-distributed-primitives/heartbeat/) |
| Block checksums for silent-corruption detection | [`02-distributed-primitives/checksum/`](../../../02-distributed-primitives/checksum/) |
| Operation log + checkpoint recovery | [`02-distributed-primitives/write-ahead-log/`](../../../02-distributed-primitives/write-ahead-log/) |
| Chunked, replicated placement and re-replication | [`01-foundations/replication/`](../../../01-foundations/replication/) |
| Lease expiry vs. a stale primary that still thinks it holds the lock | [`02-distributed-primitives/split-brain-and-fencing/`](../../../02-distributed-primitives/split-brain-and-fencing/) |
| The same problem solved as an object store | [`06-system-designs/s3/`](../../../06-system-designs/s3/) |

## Reading guide

**If you have 20 minutes**, read in this order:

1. **§2.1 Assumptions** — the whole paper follows from this list. If you read nothing else, read this.
2. **§2.3–2.5 Architecture, Single Master, Chunk Size** — the shape of the system.
3. **§2.7 Consistency Model** (including §2.7.2, implications for applications) — the most
   important and most-skipped section.
4. **§3.1–3.3 Leases, Data Flow, Atomic Record Append** — the actual write protocol.

**Then, if you have more time**: §4.4 Garbage Collection and §4.5 Stale Replica Detection are short
and unusually instructive about operating a system at scale.

**Skip on a first pass**: §6 (measurements on 2003 hardware — 100 Mbps links and 1.4 GHz CPUs, so
the absolute numbers tell you nothing today, though §6.3.3 on appends-versus-writes is a good
workload sanity check) and §8 Related Work.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this guide
- [`../../../docs/restructure-proposal.md`](../../../docs/restructure-proposal.md) — overall repo structure
- [`../../../docs/content-map.md`](../../../docs/content-map.md) — lesson → lab mapping
