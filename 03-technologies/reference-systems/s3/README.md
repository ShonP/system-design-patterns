# Amazon S3

📄 **Primary sources** — unlike the other systems in this directory, S3 has **no canonical
academic paper**. It launched on 14 March 2006 as a product, not a publication, and what is known
about its internals comes from a small number of good public sources:

- Andy Warfield (AWS VP & Distinguished Engineer). *Building and operating a pretty big storage
  system called S3*. All Things Distributed, July 2023 — the written version of his USENIX FAST '23
  keynote.
  [Article](https://www.allthingsdistributed.com/2023/07/building-and-operating-a-pretty-big-storage-system.html)
  · [Keynote](https://www.usenix.org/conference/fast23/presentation/warfield)
- James Bornholt, Rajeev Joshi, Vytautas Astrauskas, Brendan Cully, Bernhard Kragl, Seth Markle,
  Kyle Sauri, Drew Schleit, Grant Slatton, Serdar Tasiran, Jacob Van Geffen, and Andrew Warfield.
  *Using Lightweight Formal Methods to Validate a Key-Value Storage Node in Amazon S3*. SOSP 2021 —
  the ShardStore paper, the only peer-reviewed description of an S3 internal component.
  [PDF](https://www.cs.utexas.edu/~bornholt/papers/shardstore-sosp21.pdf)
- [AWS: Amazon S3 Strong Consistency](https://aws.amazon.com/s3/consistency/) and the
  [S3 performance design patterns](https://docs.aws.amazon.com/AmazonS3/latest/userguide/optimizing-performance.html)
  documentation.

> **This is a paper guide, not a runnable lab.** For the design exercise, see
> [`06-system-designs/s3/`](../../../06-system-designs/s3/). Treat anything below that is not
> attributable to the sources above as an inference, and prefer the AWS documentation for anything
> you intend to depend on — S3's internals have changed repeatedly and will change again.

## What it is, and why it mattered

S3 is an object store: you `PUT` a whole object under a key in a bucket and `GET` it back over
HTTP, and that is essentially the entire contract. No directories, no partial writes, no file
handles, no mount. What made it matter was not the technology but the shape of the abstraction. By
removing the filesystem — hierarchy, mutability, POSIX semantics, capacity planning — S3 turned
durable storage into something with no fixed size, no provisioning step, and no operational surface,
which is exactly what made "just put it in S3" the default answer for two decades of architecture.

It also quietly dissolved the premise of [GFS](../gfs/) and [HDFS](../hdfs/). Those systems assumed
compute should move to the data. S3 assumed the network was fast enough that storage and compute
could be separated and scaled independently — and won the argument decisively. Nearly every modern
analytics stack (Snowflake, Databricks, Athena, Iceberg, Delta Lake) is built on that separation.

The scale figures Warfield published in July 2023 give a sense of what the design has to absorb:
over 280 trillion objects, averaging over 100 million requests per second, across millions of hard
drives.

## The core design

### 1. A flat keyspace, and an index that makes it look hierarchical

```
   bucket "acme-logs"
   ┌──────────────────────────────────────────────────────────────┐
   │  KEY — a plain string, up to 1024 UTF-8 bytes                │
   │  "2026/08/19/app-a/00001.log"   ← the slashes mean NOTHING   │
   │  "2026/08/19/app-a/00002.log"     to S3; they are just       │
   │  "2026/08/19/app-b/00001.log"     characters in a key        │
   └──────────────────────────────────────────────────────────────┘
                    │
                    ▼
   INDEX / KEYMAP — a partitioned key-value index, ordered by key
   ┌───────────────────┬───────────────────┬───────────────────┐
   │ partition 1       │ partition 2       │ partition 3       │
   │ "2026/08/19/a…"   │ "2026/08/19/b…"   │ "2026/08/20/…"    │
   │ key → metadata    │ key → metadata    │ key → metadata    │
   │   + shard locs    │   + shard locs    │   + shard locs    │
   └───────────────────┴───────────────────┴───────────────────┘
      ▲  LIST with prefix="2026/08/19/" and delimiter="/" is a range
      │  scan over this ordered index. "Folders" are an illusion the
      │  delimiter produces, in the API and in the console.

   STORAGE LAYER — erasure-coded shards spread over AZs and drives
   object ──► k data shards + m parity shards; any k of (k+m) rebuild it
   ┌────────────────────┐ ┌────────────────────┐ ┌────────────────────┐
   │        AZ 1        │ │        AZ 2        │ │        AZ 3        │
   │  ▪ ▪   ▪     ▪     │ │    ▪   ▪ ▪   ▪     │ │  ▪    ▪   ▪  ▪     │
   │  shards land on    │ │  distinct drives   │ │  out of millions   │
   └────────────────────┘ └────────────────────┘ └────────────────────┘
```

### 2. Objects are immutable

There is no append and no in-place update. A `PUT` to an existing key writes a wholly new object;
versioning keeps the old one if enabled. Multipart upload lets a large object be assembled from
parts, but the object still becomes visible atomically at completion. This is the single property
that makes everything downstream simpler: caching, replication, erasure coding and versioning all
become easy when nothing ever mutates.

### 3. Durability through erasure coding across availability zones

Objects are split into `k` data shards plus `m` parity shards, and any `k` of the `k+m` reconstruct
the object. Shards are placed on distinct drives across (for S3 Standard) at least three
availability zones. The design target is 99.999999999% — eleven nines — of annual durability, and
integrity is enforced by checksums computed and verified continuously; Warfield's 2023 figures cite
over four billion checksum computations per second.

### 4. Spreading data thinly is a performance strategy, not just a durability one

Because every customer's data is scattered in small pieces across an enormous drive fleet, a single
workload can briefly command the aggregate IOPS of far more spindles than that customer could
afford to own — Warfield's example is a genomics burst served by over a million individual disks.
The flip side is that the design depends on demand across tenants being *uncorrelated*: managing
that "heat" is a first-class operational concern at S3, not an emergent property.

### 5. ShardStore: the storage node, in Rust, with a checked reference model

The lowest layer — the per-node key-value store holding shards — was rewritten as **ShardStore**, a
log-structured store written in Rust. Its notable contribution is methodological: the team wrote an
executable reference model roughly 1% the size of the real implementation and used property-based
testing and lightweight formal methods to check the implementation against it continuously in CI.

### 6. Consistency: eventual until December 2020, strong ever since

For its first fourteen years, S3 offered read-after-write consistency only for new-object `PUT`s,
and eventual consistency for overwrites, deletes and `LIST`. On 1 December 2020, AWS made all
`GET`, `PUT` and `LIST` operations — plus changes to tags, ACLs and metadata — strongly consistent,
automatically, in all regions, with no opt-in, no price change and no stated performance cost.

### 7. Request-rate scaling is per prefix

S3 partitions the index by key range and splits partitions automatically as load grows. The
documented floor is at least 3,500 `PUT`/`COPY`/`POST`/`DELETE` and 5,500 `GET`/`HEAD` requests per
second *per partitioned prefix*, and there is no limit on the number of prefixes. This is why key
naming and throughput are related concerns at all.

## The key design decisions, and what they cost

| Decision | What it bought | What it gave up |
|---|---|---|
| **Flat namespace; no real directories** | Unlimited keys with no hierarchical metadata to lock, no directory-tree bottleneck of the kind that caps an HDFS NameNode, and listing a "folder" is just a range scan. | There is no atomic rename. Renaming a "directory" is an O(n) sequence of copies and deletes, which is why Hadoop and Spark commit protocols on S3 were slow, expensive and — before strong consistency — genuinely unsafe. Recursive delete, move and per-directory permissions are all client-side loops over an illusion. **This is the deepest impedance mismatch when migrating from HDFS**, and the reason table formats like Iceberg and Delta Lake exist: they add an atomic commit above an object store that cannot provide one. |
| **Immutable whole objects, no append** | Massively simpler replication, caching, versioning and erasure coding; no read-modify-write coordination anywhere in the system. | Changing one byte of a large object means rewriting it. Any workload needing a mutable file (a database file, a growing log) must build that layer itself, and log-structured formats become the norm by necessity rather than choice. |
| **Eventual consistency (2006–2020)** | Availability and latency during the years when making a globally distributed index strongly consistent for free was hard. | A generation of subtle bugs, plus an entire genre of workaround: EMRFS consistent view and S3Guard existed purely to bolt a consistent index onto S3 using DynamoDB. That AWS eventually delivered strong consistency with no price or performance penalty is the honest verdict — the original trade was more conservative than it needed to be, and everyone downstream paid for it in the meantime. |
| **Key-range-partitioned index** | Prefix listing is a cheap ordered scan, which is what makes `LIST` usable at all. | Sequential keys (timestamps, monotonic IDs) concentrate load on one partition. For years the official advice was to prepend a random hash to keys — an internal implementation detail leaking all the way into customer key design. The 2018 improvements and published per-prefix limits softened this, but key layout still shapes throughput. Note the contrast with [Dynamo](../dynamo/): S3 range-partitions so that ordered listing works; Dynamo hash-partitions so that load spreads, and gives up ordering. |
| **Erasure coding rather than 3× replication** | Eleven-nines durability at far lower storage overhead than whole-copy replication. | A read touches several nodes, and reconstruction costs CPU and network. Small objects amortise badly against per-shard and per-request overhead — visible to customers as per-request pricing and minimum billable object sizes in the colder tiers. |
| **Extreme multi-tenancy on shared hardware** | Any customer can burst onto a fleet far larger than they could ever justify buying. | It only works while tenant demand stays uncorrelated, so heat management is permanent work. And per-request latency has a floor set by network and shared infrastructure — S3 is not, and cannot be, a local disk. |
| **HTTP request-per-object API** | Reachable from anywhere, cacheable by ordinary CDN and proxy infrastructure, no client library or mount required, and no connection state to manage. | Per-request overhead makes many-small-objects workloads expensive and slow, and latency is milliseconds rather than microseconds — which is precisely the gap S3 Express One Zone and the various caching layers were introduced to fill. |
| **Storage fully disaggregated from compute** | Storage and compute scale, fail and get billed independently. This is what displaced HDFS. | Data locality as an optimisation is gone; you pay for the network on every read, and throughput planning becomes a bandwidth question rather than a placement question. |

## What it influenced

- **The S3 API became the de facto standard for object storage.** MinIO, Ceph's RADOS Gateway,
  Cloudflare R2, Backblaze B2 and Wasabi all speak it, and Google Cloud Storage offers an
  S3-compatible XML API. Very few APIs achieve this; the ones that do usually got there by being
  early and small enough to reimplement.
- **The lakehouse.** Apache Iceberg, Delta Lake and Apache Hudi are, structurally, atomic-commit and
  consistent-listing layers built on top of an object store that natively provides neither. Their
  existence is a direct consequence of the flat-namespace and (historically) eventual-consistency
  decisions above.
- **Separation of storage and compute** as the default architecture for analytics — Snowflake,
  Databricks, Athena, Redshift Spectrum, BigQuery's storage layer. The premise that GFS and HDFS
  were built to deny.
- **Presigned URLs and direct client uploads** as the standard pattern for handling large files
  without proxying them through application servers.
- **Lightweight formal methods in industrial systems engineering.** The ShardStore work is widely
  cited as the practical demonstration that a small executable reference model plus property-based
  testing in CI is affordable for a real production storage node.

## Where to see these ideas running in this repo

| Idea | Lab |
|---|---|
| Designing an object store end to end | [`06-system-designs/s3/`](../../../06-system-designs/s3/) |
| Presigned URLs, multipart upload, direct-to-storage transfer | [`04-patterns/large-blobs/`](../../../04-patterns/large-blobs/) |
| Erasure coding vs. whole-copy replication, and placement across failure domains | [`01-foundations/replication/`](../../../01-foundations/replication/) |
| End-to-end checksums and silent corruption | [`02-distributed-primitives/checksum/`](../../../02-distributed-primitives/checksum/) |
| Log-structured storage, as in ShardStore | [`02-distributed-primitives/write-ahead-log/`](../../../02-distributed-primitives/write-ahead-log/) and [`02-distributed-primitives/segmented-log/`](../../../02-distributed-primitives/segmented-log/) |
| Range partitioning vs. hash partitioning, and key design as a throughput lever | [`03-technologies/databases/dynamodb/`](../../databases/dynamodb/) and [`01-foundations/consistent-hashing/`](../../../01-foundations/consistent-hashing/) |
| The hierarchical filesystems S3 replaced | [`../gfs/`](../gfs/) and [`../hdfs/`](../hdfs/) |

## Reading guide

There is no single paper to read, so read in this order:

1. **Warfield's article (~20 minutes)** — start here. The sections on physics of hard drives, on
   spreading heat across the fleet, and on durability as an organisational practice rather than a
   replication factor are the parts you will not find anywhere else.
2. **The AWS strong-consistency page (5 minutes)** — short, and it tells you exactly what the
   current contract is. Read it before you reason about anything involving reads after writes.
3. **The AWS performance-optimisation guide** — the per-prefix request rates and multipart-upload
   guidance, which is where the index design becomes visible to you as a user.
4. **The ShardStore paper, §2 and §3** — the storage node's design and the reference-model
   methodology. Skip §5–6 (the verification details) unless you are specifically interested in
   applying the technique.

**Treat with caution**: third-party "S3 architecture" diagrams, including the many that circulate in
system-design interview material. Most are extrapolations from the sources above plus guesswork,
and the details they invent (specific shard counts, specific index designs) are not attributable.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this guide
- [`../../../docs/restructure-proposal.md`](../../../docs/restructure-proposal.md) — overall repo structure
- [`../../../docs/content-map.md`](../../../docs/content-map.md) — lesson → lab mapping
