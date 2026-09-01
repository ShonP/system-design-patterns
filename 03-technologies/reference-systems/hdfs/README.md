# Hadoop Distributed File System (HDFS)

📄 **Paper**: Konstantin Shvachko, Hairong Kuang, Sanjay Radia, and Robert Chansler. *The Hadoop
Distributed File System*. MSST 2010 — IEEE 26th Symposium on Mass Storage Systems and Technologies,
Incline Village, NV, May 2010. [PDF mirror](https://pages.cs.wisc.edu/~akella/CS838/F15/838-CloudPapers/hdfs.pdf) ·
[DOI 10.1109/MSST.2010.5496972](https://doi.org/10.1109/MSST.2010.5496972)

> **This is a paper guide, not a runnable lab.** The last section links the labs in this repo where
> HDFS's underlying ideas run as code.

## What it is, and why it mattered

HDFS is the open-source realisation of [GFS](../gfs/), written at Yahoo! as the storage layer of
Apache Hadoop. Its historical importance is not architectural novelty — it is that it took a design
only Google could run and made it something any company could download. The paper is also more
valuable than a pure design document because it is an *operations* paper: it reports what running
25 PB across 25,000 servers actually looked like, where the design hurt, and what the team planned
to do about it. Much of what it calls future work (automatic NameNode failover via ZooKeeper,
namespace scaling) became Hadoop 2, so reading it tells you both the design and why the next
version looks the way it does.

## The core design

### 1. NameNode holds the namespace; DataNodes hold the bytes

```
                   ┌──────────────────────────────────────────────────┐
  1. create /open  │  NAMENODE — single; whole namespace in RAM       │
     a path        │   • inodes: names, permissions, quotas, repl.    │
  ┌───────────────►│   • file → block list                            │
  │  2. block ID + │   • image (checkpoint) + journal (edit log)      │
  │     DataNode   │   • block → DataNode map: rebuilt from block     │
  │     list       │     reports at startup, NEVER persisted          │
  │◄───────────────└────────────────────────┬─────────────────────────┘
  │                                         │  every 3s each DataNode heartbeats
┌─┴───────┐                                 │  (ten minutes of silence marks it
│ CLIENT  │                                 │  dead) and periodically sends a
└─┬───────┘                                 │  block report. The NameNode never
  │                                         │  calls a DataNode — its commands
  │  3. write pipeline:                     │  ride back on heartbeat replies.
  │     ~64 KB packets forward,             │
  │     acks back                           │
  │  ┌────────────┐   ┌────────────┐   ┌────┴───────┐
  └─►│  DataNode  ├──►│  DataNode  ├──►│  DataNode  │
     │   rack 1   │   │   rack 2   │   │   rack 2   │
     └────────────┘   └────────────┘   └────────────┘
      each replica on disk = the block file + a meta file
      holding its checksums and generation stamp
```

Files are split into blocks — typically 128 MB, selectable per file — and each block is replicated,
typically three times, again selectable per file. The NameNode keeps the whole namespace in memory.
Crucially, it does *not* persist block locations: those are reconstructed from DataNode block
reports at startup, because the DataNodes are the authority on what they actually hold.

### 2. Image and journal

The persistent namespace is a **checkpoint** (the image on disk) plus a **journal** — a write-ahead
log of namespace changes. The NameNode replays the journal onto the checkpoint at startup. A
**CheckpointNode** periodically compacts the two into a fresh checkpoint; a **BackupNode** goes
further and maintains a live in-memory copy of the namespace by consuming the journal stream,
making it "a read-only NameNode".

### 3. Heartbeats are the entire control plane

DataNodes heartbeat every three seconds by default; ten minutes of silence marks a DataNode dead
and triggers re-replication of everything it held. Heartbeats also carry capacity, utilisation and
in-flight transfer counts, which feed placement and balancing. The NameNode never initiates a call
to a DataNode — commands (replicate this block, delete that one, re-register, shut down, send a
block report) ride back on heartbeat *replies*. That inversion is why a single NameNode can process
thousands of heartbeats per second while remaining the only decision maker.

### 4. Single-writer, write-once files

An HDFS file has one writer at a time, holding a **lease** on the path with a soft limit (after
which another client may preempt) and a hard limit of one hour (after which HDFS closes the file on
the writer's behalf and recovers the lease). Once closed, bytes cannot be altered — only appended
by reopening. Readers are unlimited and unaffected by the writer's lease.

### 5. Write pipeline

The client asks the NameNode for DataNodes to host the next block, then arranges them into a
pipeline ordered to minimise total network distance. Bytes flow as ~64 KB packets, and the client
may have several packets in flight before earlier ones are acknowledged. When a block fills, a new
pipeline is built for the next one.

### 6. Rack-aware placement

The default policy places the first replica on the writer's own node, the second and third on two
different nodes in a *different* rack, and any further replicas on random nodes subject to no more
than one replica per node and no more than two per rack. This survives a whole-rack failure while
keeping only one cross-rack hop on the write path. The NameNode treats a block whose replicas all
landed in one rack as under-replicated and fixes it.

### 7. Integrity and background repair

Each block replica is two local files: the data, and a metadata file holding checksums and a
generation stamp. A per-DataNode **block scanner** periodically re-verifies replicas. On detecting
corruption the NameNode does not delete the bad replica first — it replicates a good copy up to the
replication factor, and only then removes the corrupt one. A **balancer** moves replicas to even
out disk utilisation while preserving the rack invariants and minimising cross-rack copying.

## The key design decisions, and what they cost

| Decision | What it bought | What it gave up |
|---|---|---|
| **Single NameNode with the namespace in RAM** | Simple, fast metadata operations and globally optimal placement, like GFS. | Namespace size is capped by the NameNode heap, which the paper names as "a key struggle". This is the origin of Hadoop's **small files problem**: a million tiny files cost as much metadata as a million huge ones, so HDFS is actively bad at the workload most filesystems handle fine. Fixed later by *Federation* (multiple independent namespaces sharing the DataNode pool), not by making one NameNode bigger. |
| **NameNode is not replicated for failover (as published)** | Enormously simpler than a consensus-replicated metadata service, and acceptable because Hadoop was a batch system where a restart was tolerable. | The paper states plainly that the cluster is "effectively unavailable when its NameNode is down", and that automated failover was still future work — the plan being to use ZooKeeper. That plan shipped in Hadoop 2 as a standby NameNode plus ZKFC and the Quorum Journal Manager. **This is the part that aged worst**, and it is why HDFS deployments today look nothing like the paper's diagram. |
| **Block locations are never persisted** | The NameNode can never be wrong about where data lives in a way that outlives a restart; DataNodes are the source of truth. | Startup is slow: the NameNode cannot serve reads until enough block reports have arrived (safe mode). On a large cluster this is minutes, not seconds. |
| **Write-once, single-writer** | Replica consistency becomes trivial — there is one writer, so there is one order. No record-append machinery, no undefined regions, none of GFS's duplicate-filtering burden on applications. | No concurrent appenders, so the producer/consumer queue pattern GFS enabled is simply unavailable; append itself arrived years after the initial design. Random writes are impossible. |
| **3× replication** | Simple, fast recovery, and read parallelism — three places to read every block from. | 200% storage overhead. Hadoop 3 added Reed–Solomon erasure coding to trade CPU and repair-time network for that space. |
| **Rack-awareness assumed as a two-level tree** | Cheap, correct-enough locality and failure-domain modelling. | Encodes a datacentre topology that stopped being universal; in cloud environments "rack" has to be mapped onto availability zones, and the write path's one guaranteed cross-rack hop becomes a cross-AZ hop with very different cost. |
| **Optimised for MapReduce-style streaming** | Excellent aggregate throughput per node; the paper reports per-node bandwidth scaling linearly to 3500 nodes. | Poor latency for small random reads, and the whole design assumes compute is co-located with storage. The disaggregated-storage model that object stores made normal is the opposite bet. |

## What it influenced

- **HBase** is to HDFS what Bigtable is to GFS — it stores HFiles (≈ SSTables) and write-ahead logs
  on HDFS and uses ZooKeeper where Bigtable uses Chubby.
- **The Hadoop ecosystem** — Hive, Pig, and later Spark — all assumed the HDFS contract: immutable
  large files, block locality, and a job scheduler that moves computation to the data.
- **ZooKeeper's role as the standard failover arbiter** in the Apache world traces partly to this
  paper's stated plan. HDFS HA (Hadoop 2, 2012) uses ZooKeeper for leader election between an
  active and standby NameNode, plus a quorum of JournalNodes for the shared edit log — replacing
  the BackupNode described here.
- **Its own displacement**: the compute–storage co-location premise is exactly what S3 and other
  object stores dissolved. Most workloads that would have run on HDFS in 2012 now run against an
  object store with a metadata catalogue on top. Reading the paper's motivation section and then
  the S3 guide is the fastest way to see what changed and why.

## Where to see these ideas running in this repo

| Idea from the paper | Lab |
|---|---|
| Heartbeats as liveness *and* as the command channel | [`02-distributed-primitives/heartbeat/`](../../../02-distributed-primitives/heartbeat/) |
| Journal + checkpoint recovery | [`02-distributed-primitives/write-ahead-log/`](../../../02-distributed-primitives/write-ahead-log/) and [`02-distributed-primitives/segmented-log/`](../../../02-distributed-primitives/segmented-log/) |
| Write leases with soft and hard limits | [`02-distributed-primitives/lease/`](../../../02-distributed-primitives/lease/) |
| Block checksums and background scanning | [`02-distributed-primitives/checksum/`](../../../02-distributed-primitives/checksum/) |
| Replica placement and rack-aware failure domains | [`01-foundations/replication/`](../../../01-foundations/replication/) |
| The ZooKeeper-based failover HDFS eventually adopted | [`03-technologies/coordination/zookeeper/`](../../coordination/zookeeper/) |
| Avoiding two active NameNodes | [`02-distributed-primitives/split-brain-and-fencing/`](../../../02-distributed-primitives/split-brain-and-fencing/) |
| The object-store alternative | [`06-system-designs/s3/`](../../../06-system-designs/s3/) |

## Reading guide

**If you have 20 minutes:**

1. **§II.A–II.C (NameNode, DataNodes, HDFS Client)** — the architecture, in three pages.
2. **§II.D–II.F (Image and Journal, CheckpointNode, BackupNode)** — how metadata survives a crash,
   and what "HA" meant before Hadoop 2.
3. **§III.A (File Read and Write)** — the lease model and the write pipeline.
4. **§III.B–III.E (Block Placement, Replication Management, Balancer, Block Scanner)** — the
   background machinery that actually keeps the cluster healthy.

**Then**: **§V (Future Work)** is unusually worth reading, because you already know how the story
ends — it names automated failover via ZooKeeper and namespace scalability as the two open problems,
and both were solved in the next major version.

**Skip on a first pass**: §IV (Practice at Yahoo!) is interesting as history but the benchmark
numbers are 2010 hardware; read only the cluster-shape statistics if anything.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this guide
- [`../../../docs/restructure-proposal.md`](../../../docs/restructure-proposal.md) — overall repo structure
- [`../../../docs/content-map.md`](../../../docs/content-map.md) — lesson → lab mapping
