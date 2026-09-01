# Bigtable

📄 **Paper**: Fay Chang, Jeffrey Dean, Sanjay Ghemawat, Wilson C. Hsieh, Deborah A. Wallach,
Mike Burrows, Tushar Chandra, Andrew Fikes, and Robert E. Gruber. *Bigtable: A Distributed Storage
System for Structured Data*. OSDI '06 — 7th USENIX Symposium on Operating Systems Design and
Implementation, Seattle, WA, November 2006. (Extended version in *ACM TOCS* 26(2), 2008.)
[Canonical PDF](https://static.googleusercontent.com/media/research.google.com/en//archive/bigtable-osdi06.pdf)

> **This is a paper guide, not a runnable lab.** The last section links the labs in this repo where
> Bigtable's ideas run as code — most directly Cassandra, which inherited its storage engine.

## What it is, and why it mattered

Bigtable is the paper that showed you could get most of the useful properties of a database at a
scale where databases did not work, by giving up almost everything except one: a sorted key space.
It is described by its authors as "a sparse, distributed, persistent multi-dimensional sorted map"
indexed by `(row key, column key, timestamp)` and yielding uninterpreted bytes. No joins, no
schema for columns, no cross-row transactions, no query language. What you get instead is that rows
are stored in lexicographic order, which means *you* control physical locality through key design,
and range scans are cheap. Nearly every scale-out store built since — HBase, Cassandra, Accumulo,
and the LevelDB/RocksDB engines underneath a great deal else — is a variation on the machinery in
this paper.

## The core design

### 1. The data model

```
                     ┌── "contents:" ──┬─────────────── "anchor:" ────────────────┐
  row key            │  contents:      │  anchor:cnnsi.com  │  anchor:my.look.ca  │
─────────────────────┼─────────────────┼────────────────────┼─────────────────────┤
  "com.cnn.www"      │  t9 "<html>…"   │  t8 "CNN"          │  t9 "CNN.com"       │
                     │  t6 "<html>…"   │                    │                     │
                     │  t3 "<html>…"   │                    │                     │
─────────────────────┴─────────────────┴────────────────────┴─────────────────────┘
     ▲                ▲                    ▲
     │                │                    └─ column key = family:qualifier
     │                └─ a cell holds several timestamped versions,
     │                   garbage-collected by count or by age
     └─ rows sort lexicographically, so URLs are stored REVERSED and
        pages from one site land in one tablet. Key design IS layout.
```

**Row keys** are arbitrary strings up to 64 KB, though 10–100 bytes is typical.
**Column families** must be declared before use and are few; they are the unit of access control,
accounting, and garbage-collection policy. **Column qualifiers** within a family are unbounded and
created on the fly. Every read or write under a single row key is atomic regardless of how many
columns it touches, and Bigtable also offers single-row read-modify-write transactions — but
nothing across rows.

### 2. Tablets

A table is dynamically partitioned by row range into **tablets**, roughly 100–200 MB each by
default, splitting as they grow. A tablet is the unit of distribution and load balancing, and it is
served by exactly one tablet server at a time.

### 3. Three-level tablet location, like a B+-tree

```
 Chubby file  ──►  root tablet  ──►  other METADATA  ──►  user tablets
 (bootstrap        (1st METADATA     tablets              (the actual data)
  location)         tablet; never    ~1 KB per row
                    splits)
```

The client library caches locations and walks *up* the hierarchy when its cache is wrong or empty.
Because each METADATA row is about 1 KB and METADATA tablets are capped at 128 MB, three levels
address 2³⁴ tablets — enough that a fourth level is never needed.

### 4. Master does assignment, not serving

The master assigns tablets to tablet servers, detects servers joining and expiring, balances load,
garbage-collects GFS files, and handles schema changes. Clients never route data through it, so
the master is lightly loaded — and a Bigtable cluster keeps serving reads and writes for existing
tablet assignments while the master is down.

### 5. Storage: commit log + memtable + SSTables (the LSM shape)

```
   write ──► commit log (GFS, append-only) ──► memtable (sorted, in RAM)
                                                  │  minor compaction, when full
                                                  ▼
                          SSTable  SSTable  SSTable  ...   (immutable, in GFS)
                                                  │  merging compaction
                                                  ▼
                                          fewer, larger SSTables
                                                  │  major compaction
                                                  ▼
                                  exactly one SSTable, no deletion entries
   read  ──► merged view of memtable + all SSTables for the tablet
```

An **SSTable** is a persistent, ordered, immutable map: a sequence of blocks (typically 64 KB) plus
a block index loaded into memory when the file is opened, so a lookup is one disk seek. A **major
compaction** is the only thing that truly removes deleted data — until then, deletion entries in
newer SSTables merely suppress values in older ones.

### 6. Chubby is load-bearing in five separate ways

Bigtable uses [Chubby](../chubby/) to ensure there is at most one active master, to store the
bootstrap location of the root tablet, to discover tablet servers and finalise their deaths, to
store schema information, and to store access control lists. A tablet server acquires an exclusive
lock on a file in a Chubby directory; losing that lock means it stops serving.

### 7. The refinements are where the performance actually comes from

- **Locality groups** — a client groups column families that are read together; each group gets its
  own SSTable per tablet, and a group can be declared in-memory so it never touches disk.
- **Compression** per block, with a client-chosen scheme; the paper describes a two-pass custom
  scheme that compresses across a large window and gets extreme ratios on Webtable because many
  pages from one host are stored adjacently — a direct payoff of the reversed-URL key design.
- **Two caches** — a Scan Cache for key/value pairs (good for repeated reads) and a Block Cache for
  SSTable blocks (good for reads near recent reads).
- **Bloom filters** per SSTable per locality group, so a read can skip SSTables that cannot contain
  the row.
- **One commit log per tablet server**, not per tablet — vastly fewer concurrent GFS writes, at the
  price of complicated recovery (the log must be sorted by `(table, row, log sequence number)` and
  the relevant fragments handed to each new server).
- **Exploiting immutability** — SSTables never change, so reads need no synchronisation at all;
  only the memtable needs concurrency control, done with copy-on-write per row.

## The key design decisions, and what they cost

| Decision | What it bought | What it gave up |
|---|---|---|
| **Sorted rows, no secondary indexes, no query language** | Range scans are sequential I/O; locality is under the application's control; the server stays simple enough to run thousands of tablets. | The row key is your only index, so the key *is* the schema. A wrong key means a hot tablet or a full-table scan, and changing it means rewriting the table. Every "wide row" and "bucketed partition key" trick in later systems is a consequence of this. |
| **Single-row atomicity only, no cross-row transactions** | No distributed commit protocol, no locking across servers, and each tablet server can act independently. | Applications denormalise and maintain multi-row invariants themselves. Google's own answer was to build *on top*: Megastore added entity-group transactions, and Spanner eventually brought back general transactions with synchronised clocks. |
| **One tablet server owns a tablet exclusively** | Strong per-row consistency without any quorum or replication protocol inside Bigtable — GFS already handles durability, so a tablet server is just a cache with a log. | A tablet is unavailable from the moment its server dies until the master reassigns it and the new server replays the log. There are no read replicas, so a hot tablet cannot be scaled by adding copies. |
| **Layering on GFS and Chubby instead of solving replication and consensus itself** | An enormous amount of the hard work was already done and already operationally understood. | Availability is now the product of three systems. Every read that misses cache is a GFS round trip. And if Chubby is unreachable for longer than a tablet server's session, that server stops serving — Bigtable's availability is *bounded above* by Chubby's. |
| **A single shared commit log per tablet server** | Far better write throughput than one GFS file per tablet. | Recovery is genuinely awkward — the paper spends a page on sorting and partitioning log fragments, and on a two-log workaround for GFS write hiccups. This is the least elegant part of the design and the paper says so. |
| **Timestamped versions with policy-based GC** | Free history, cheap "keep the last N" or "keep the last week" semantics. | Deleted and superseded data sits on disk consuming space and read-time merge work until the next major compaction. Anyone who has fought Cassandra tombstones is meeting this decision again. |
| **Client library holds the cluster logic** | The master stays out of the data path and the servers stay simple. | A fat, stateful client with a location cache that can go stale; correctness depends on clients handling misdirected requests and walking the hierarchy again. |

## What it influenced

- **HBase** is close to a direct port: HRegion ≈ tablet, HRegionServer ≈ tablet server, HMaster ≈
  master, HFile ≈ SSTable, with HDFS in place of GFS and ZooKeeper in place of Chubby.
- **Cassandra takes exactly half of its design from here, and the split is worth stating
  precisely**: the *storage engine and data model* — commit log, memtable, SSTables, compaction,
  column families, wide sorted rows — are Bigtable's. The *distribution layer* — consistent-hashing
  ring, replication factor, tunable quorums, gossip, hinted handoff, read repair — is
  [Dynamo's](../dynamo/). Cassandra is a Dynamo ring where each node runs a Bigtable-style engine.
- **LevelDB and, through it, RocksDB** distil the SSTable/memtable/compaction machinery into an
  embeddable library; LevelDB was written by Jeff Dean and Sanjay Ghemawat, two of this paper's
  authors. A remarkable amount of modern storage sits on that lineage.
- **The LSM-tree as the default write path.** The log-structured merge-tree predates Bigtable
  (O'Neil et al., 1996), but Bigtable is what made it the standard answer for write-heavy
  distributed stores rather than an academic curiosity.
- **Google's own line forward**: Bigtable → Megastore → Spanner, each step buying back a piece of
  the transactional semantics this paper gave away. Cloud Bigtable is the productised service and
  still exposes essentially this data model.
- **Accumulo** (cell-level security) and **Hypertable** are further direct descendants.

## Where to see these ideas running in this repo

| Idea from the paper | Lab |
|---|---|
| Bigtable's data model and storage engine, running for real | [`03-technologies/databases/cassandra/`](../../databases/cassandra/) — notebooks 1, 2 and 4 cover partition keys, wide rows/clustering, and LSM compaction |
| Commit log before memtable | [`02-distributed-primitives/write-ahead-log/`](../../../02-distributed-primitives/write-ahead-log/) |
| Log segmentation and reclamation | [`02-distributed-primitives/segmented-log/`](../../../02-distributed-primitives/segmented-log/) |
| The coordination service Bigtable depends on | [`../chubby/`](../chubby/) → [`03-technologies/coordination/zookeeper/`](../../coordination/zookeeper/) |
| Ensuring only one server owns a tablet | [`02-distributed-primitives/split-brain-and-fencing/`](../../../02-distributed-primitives/split-brain-and-fencing/) and [`02-distributed-primitives/lease/`](../../../02-distributed-primitives/lease/) |
| The filesystem underneath | [`../gfs/`](../gfs/) |
| Key design as the primary scaling lever | [`03-technologies/databases/dynamodb/`](../../databases/dynamodb/) |

## Reading guide

**If you have 20 minutes:**

1. **§2 Data Model** — three pages, and everything else depends on understanding that the row key
   controls physical layout.
2. **§5.1–5.3 Tablet Location, Tablet Assignment, Tablet Serving** — the runtime architecture.
3. **§5.4 Compactions** — minor / merging / major, which is the whole LSM story in half a page.
4. **§6 Refinements** — do not skip this thinking it is an appendix. Locality groups, Bloom filters
   and the commit-log discussion are where the design meets reality.

**Then**: **§9 Lessons** is short and blunt about what large distributed systems actually fail from
(not the failures you designed for), and **§8 Real Applications** shows three very different
workloads mapped onto the same key space.

**Skip on a first pass**: §7 Performance Evaluation (2006 hardware) and §10 Related Work.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this guide
- [`../../../docs/restructure-proposal.md`](../../../docs/restructure-proposal.md) — overall repo structure
- [`../../../docs/content-map.md`](../../../docs/content-map.md) — lesson → lab mapping
