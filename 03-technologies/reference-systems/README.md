# Reference systems — the papers everything else is built on

These are **paper guides, not runnable labs**. Each one is a design document
rather than a piece of software, so the useful artifact is a careful reading
with the trade-offs made explicit — plus links to the labs in this repo where
the same ideas do run as code.

| System | Paper | Read it for |
|---|---|---|
| [`gfs/`](gfs/) | Ghemawat, Gobioff & Leung — *The Google File System*, SOSP '03 | Single master + chunkservers, 64 MB chunks, leases for mutation ordering, atomic record append, and a consistency model deliberately weakened to fit the workload |
| [`hdfs/`](hdfs/) | Shvachko, Kuang, Radia & Chansler — *The Hadoop Distributed File System*, MSST 2010 | What survived the GFS design in an open-source reimplementation, and what did not — including the NameNode as a single point of failure |
| [`bigtable/`](bigtable/) | Chang et al. — *Bigtable: A Distributed Storage System for Structured Data*, OSDI '06 | Sparse sorted maps, tablets and SSTables, the LSM write path, and how it leans on GFS and Chubby rather than solving those problems again |
| [`dynamo/`](dynamo/) | DeCandia et al. — *Dynamo: Amazon's Highly Available Key-value Store*, SOSP '07 | Consistent hashing, sloppy quorums, vector clocks, hinted handoff, Merkle-tree anti-entropy — availability bought by pushing conflict resolution to the application |
| [`chubby/`](chubby/) | Burrows — *The Chubby Lock Service for Loosely-Coupled Distributed Systems*, OSDI '06 | Coarse-grained locking, sessions and leases, and the argument for giving developers a lock service instead of a consensus library |
| [`s3/`](s3/) | No academic paper — see the guide for the primary sources | Object storage at scale: the metadata plane as the real system, durability vs availability, and why third-party "S3 architecture" diagrams should be treated with suspicion |

## Suggested order

1. **GFS** — the original move: measure your workload, then weaken the contract.
2. **Bigtable** — what you build once you have a filesystem and a lock service.
3. **Chubby** — the lock service Bigtable depends on.
4. **Dynamo** — the opposite bet: give up consistency to never refuse a write.
5. **HDFS** — GFS reimplemented in the open, and what the copy lost.
6. **S3** — where this lineage ended up commercially.

## Where these ideas run as code in this repo

| Idea | Lab |
|---|---|
| Consistent hashing and the ring | [`01-foundations/consistent-hashing`](../../01-foundations/consistent-hashing/) |
| Quorums and `R + W > N` | [`02-distributed-primitives/quorum`](../../02-distributed-primitives/quorum/) |
| Vector clocks and conflict detection | [`02-distributed-primitives/vector-clocks`](../../02-distributed-primitives/vector-clocks/) |
| Hinted handoff and read repair | [`02-distributed-primitives/hinted-handoff`](../../02-distributed-primitives/hinted-handoff/) · [`read-repair`](../../02-distributed-primitives/read-repair/) |
| Merkle-tree anti-entropy | [`02-distributed-primitives/merkle-trees`](../../02-distributed-primitives/merkle-trees/) |
| Leases and fencing | [`02-distributed-primitives/lease`](../../02-distributed-primitives/lease/) · [`split-brain-and-fencing`](../../02-distributed-primitives/split-brain-and-fencing/) |
| Write-ahead and segmented logs | [`02-distributed-primitives/write-ahead-log`](../../02-distributed-primitives/write-ahead-log/) · [`segmented-log`](../../02-distributed-primitives/segmented-log/) |
| A Chubby-shaped coordination service | [`03-technologies/coordination/zookeeper`](../coordination/zookeeper/) |
| Bigtable's storage model + Dynamo's ring | [`03-technologies/databases/cassandra`](../databases/cassandra/) |
| The commercial descendant of Dynamo | [`03-technologies/databases/dynamodb`](../databases/dynamodb/) |
| Designing object storage yourself | [`06-system-designs/s3`](../../06-system-designs/s3/) |
