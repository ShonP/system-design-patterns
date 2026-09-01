# YouTube System Design

A hands-on system design exercise where we build a video-sharing platform step by step — learning from bad practices and evolving toward good ones.

---

## Functional Requirements

### In Scope

| # | Requirement |
|---|-------------|
| 1 | Users can **upload videos** |
| 2 | Users can **watch (stream) videos** |

### Out of Scope

- Users can view information about a video (view counts)
- Users can search for videos
- Users can comment on videos
- Users can see recommended videos
- Users can make a channel and manage their channel
- Users can subscribe to channels

> This question focuses on the **video-sharing** aspects of YouTube — upload and streaming. The non-functional requirements are where the real complexity lives.

---

## Non-Functional Requirements

### In Scope

| # | Requirement | Details |
|---|-------------|---------|
| 1 | **High availability** | Prioritize availability over consistency |
| 2 | **Large video support** | Upload and stream videos up to 10s of GBs |
| 3 | **Low latency streaming** | Smooth playback even in low bandwidth environments |
| 4 | **Scale** | ~1M videos uploaded/day, ~100M videos watched/day |
| 5 | **Resumable uploads** | Users can resume interrupted uploads without starting over |

### Out of Scope

- Content moderation / bad content protection
- Bot / fake account protection
- Monitoring / alerting

---

## Capacity Estimate

Assumptions: **1M uploads/day**, **100M watches/day**, average video **10 minutes**, average
viewer watches **5 minutes** of it, source upload ~**8 Mbps** (user-recorded 1080p).

### The rendition ladder is *not* N copies of the master

This is the single most commonly botched number in this design. Bitrate scales roughly with
pixel count, so the lower rungs are almost free:

| Rung | Pixels | Bitrate | Relative to 1080p |
|------|--------|---------|-------------------|
| 1080p | 2,073,600 | 5.0 Mbps | 1.00x |
| 720p  |   921,600 | 2.5 Mbps | 0.50x |
| 480p  |   409,920 | 1.0 Mbps | 0.20x |
| 360p  |   230,400 | 0.5 Mbps | 0.10x |
| **ladder total** | | **9.0 Mbps** | **1.80x** |

Storing all four qualities costs **1.8x** the 1080p rendition — not 4x. Compared with the
uploaded master at 8 Mbps, the entire ladder is **1.13x**. Adding every rung below 1080p
costs 80% more than storing 1080p alone and buys you every mobile and low-bandwidth viewer.

> Lab 2 measures this against the bytes actually written to MinIO rather than asserting it.

### Storage

```
per video (10 min):
  uploaded master @ 8.0 Mbps = 0.60 GB
  full ladder     @ 9.0 Mbps = 0.68 GB

1M uploads/day:
  renditions : 0.68 PB/day  →  ~246 PB/year
  masters    : 0.60 PB/day  →  ~219 PB/year
  ------------------------------------------
  total      : 1.28 PB/day  →  ~465 PB/year
```

**Do you keep the masters?** Keeping them roughly doubles the storage bill. You keep them
anyway: the day you adopt a new codec (H.264 → AV1) you need the source to re-encode from,
and re-encoding from your own 1080p rendition compounds compression artifacts. Cold storage
is the compromise — cheap to retain, slow to read, which is acceptable because you only read
them during a codec migration.

### Egress — the number that decides the architecture

```
per watch : 5 min @ ~2.5 Mbps average delivered = ~94 MB
per day   : 100M x 94 MB = 9.38 PB/day
average   : ~868 Gbps sustained
peak      : ~2.6 Tbps (roughly 3x average)
```

We ingest 0.60 PB/day and serve 9.38 PB/day — **~16x more out than in**. Every design
decision should be optimising the read path, which is why the CDN, not the database, is the
centre of gravity in the final architecture.

At a typical cloud egress price of $0.05/GB, 9.38 PB/day is **~$0.47M/day, ~$171M/year** if
it all left object storage. That is the number that explains why YouTube built Google Global
Cache and Netflix built Open Connect: past a certain volume you stop renting bandwidth and
start shipping your own hardware into ISPs. The CDN here is not a latency optimisation, it is
the business model.

### Transcoding compute

```
1M videos/day x 10 min = 10M video-minutes/day

Encoding one video-minute into the full 4-rung ladder with x264 costs roughly
2 CPU-minutes (dominated by the 1080p rung; the small rungs are nearly free).

10M x 2 = 20M CPU-min/day = ~333,000 CPU-hours/day
        = ~13,900 cores running flat out, 24/7
        ≈ 220 machines at 64 cores each
```

This is why the pipeline is a fan-out DAG on an elastic worker pool rather than a service:
the work is bursty, embarrassingly parallel per segment, and expensive enough that you want
the fleet to shrink overnight. It is also why hardware encoders (and, at YouTube's actual
scale, custom transcoding ASICs) pay for themselves.

### Metadata

```
1M videos/day x 365 = 365M rows/year x ~2 KB = ~730 GB/year
```

Trivial next to the video bytes. Metadata is a **latency and hot-partition** problem
(a viral video's row is read millions of times), not a capacity problem — which is exactly
what the Redis cache in the final architecture addresses.

### Request rates

```
uploads : 1M/day    ≈    12/sec average
watches : 100M/day  ≈ 1,160/sec average, ~3,500/sec at peak
```

Note how small these are. The API tier is nearly idle; **the entire difficulty of this system
is in bytes, not in requests per second.** That is the opposite of most designs in this
repo, and it is the thing to say out loud in an interview.

---

## Planning the Approach

Build the design sequentially through functional requirements, then use non-functional requirements to guide deep dives. With only 2 functional requirements, the non-functional requirements characterize most of the complexity — uploading and streaming large files at scale with low latency are deceptively hard problems.

---

## Core Entities

| Entity | Description |
|--------|-------------|
| **User** | A user of the system — either an uploader or viewer |
| **Video** | The actual video file that is uploaded and watched |
| **VideoMetadata** | Metadata associated with the video: uploading user, title, description, URL reference to the video file, transcript, duration, resolution, etc. |

---

## API Design

### Upload Video

The server never receives the video file directly. Instead, it creates a **presigned URL** for the client to upload directly to object storage (S3/MinIO).

```
POST /presigned_url

Request:
{
  title: string,
  description: string,
  contentType: string,
  fileSize: number
}

Response:
{
  videoId: string,
  uploadUrl: string,     // presigned URL for direct S3 upload
  expiresIn: number      // seconds until URL expires
}
```

Client then uploads the video file directly to the `uploadUrl` (multipart for large files). The server never proxies video bytes.

### Watch (Stream) Video

```
GET /videos/:videoId -> VideoMetadata & manifest URL
```

Returns video metadata and a **manifest file URL**. The client's video player uses the manifest to stream segments directly from CDN/S3.

---

## Background: Video Streaming Concepts

| Concept | What It Is |
|---------|-----------|
| **Video Codec** | Compresses/decompresses video (H.264, H.265, VP9, AV1). Trade-offs: compression time, platform support, quality, file size. |
| **Video Container** | File format that stores video + audio + metadata (.mp4, .webm, .mkv). Different devices support different containers. |
| **Bitrate** | Bits per second for playback (kbps/Mbps). Higher resolution + framerate = higher bitrate = more data to transfer. |
| **Manifest File** | Text file indexing video segments. Primary manifest lists available formats; media manifests list segment URLs. Used by players to stream adaptively. |

A **"video format"** = a container + codec combination (e.g., H.264 in MP4).

---

## High-Level Design

We build the system sequentially, one functional requirement at a time.

### 1. Upload Videos

```
┌────────┐  POST /presigned_url  ┌───────────────┐  save metadata  ┌────────────────┐
│        │──────────────────────>│               │───────────────>│  Cassandra /    │
│ Client │                       │ Upload Service│                │  PostgreSQL     │
│        │<─────────────────────│               │                │  (VideoMetadata)│
└───┬────┘  {uploadUrl, videoId} └───────────────┘                └────────────────┘
    │
    │  PUT (video file via presigned URL — multipart upload)
    │
    v
┌──────────────┐   S3 event    ┌──────────────────────────────────────────────┐
│   S3 / MinIO │──────────────>│  Video Processing Pipeline                  │
│  (raw video) │               │                                              │
└──────────────┘               │  1. Split into segments (few seconds each)   │
                               │  2. Transcode each segment into formats:     │
                               │     - 1080p H.264/MP4                        │
                               │     - 720p  H.264/MP4                        │
                               │     - 480p  H.264/MP4                        │
                               │     - 360p  H.264/MP4                        │
                               │  3. Generate manifest files (HLS/DASH)       │
                               │  4. Store segments + manifests in S3         │
                               │  5. Update VideoMetadata with URLs           │
                               └──────────────────────────────────────────────┘
```

**Flow:**
1. Client sends `POST /presigned_url` with video metadata (title, description, content type)
2. Upload Service creates a VideoMetadata record (status: `uploading`), generates a presigned S3 URL
3. Client uploads the video file directly to S3 via the presigned URL (multipart for large files)
4. S3 fires an event notification → Video Processing Pipeline picks up the raw video
5. Pipeline splits the video into segments, transcodes each into multiple formats, generates manifest files
6. Pipeline stores processed segments + manifests in S3, updates VideoMetadata (status: `ready`, adds manifest URL)

**Why presigned URLs?** The video file never flows through our application servers. A 10GB video uploading through our API would consume massive memory/bandwidth on the server. Presigned URLs let the client upload directly to S3 — our server only handles the lightweight metadata request.

**What we store — 3 iterations of thinking:**

| Approach | Store | Problem |
|----------|-------|---------|
| ❌ Naive | Just the raw file | Different devices need different formats — won't play everywhere |
| 🟡 Better | Raw file + transcoded formats (full files) | Can't stream "part" of a video — must download entire file |
| ✅ Great | Segments (few seconds each) × multiple formats + manifest files | Enables adaptive bitrate streaming, seeking, and partial playback |

### 2. Watch (Stream) Videos

The `GET /videos/:videoId` endpoint returns VideoMetadata (including the manifest URL). The client then streams segments directly from S3/CDN — the server never proxies video bytes.

**Three approaches to watching:**

| # | Approach | How | Problem |
|---|----------|-----|---------|
| ❌ | **Full download** | Client downloads entire video file, then plays | 10GB = 13+ min wait. Network disruption = start over. |
| 🟡 | **Segment streaming** | Client picks a format, downloads segments sequentially | No adaptation — if bandwidth drops, user buffers. |
| ✅ | **Adaptive bitrate streaming** | Client reads manifest, streams segments, switches quality based on network | Best UX — no buffering, fast startup, bandwidth-efficient. |

```
┌────────┐  GET /videos/:videoId   ┌───────────────┐  query   ┌────────────────┐
│        │────────────────────────>│               │────────> │ Video Metadata  │
│ Client │                         │ Video Service │          │ DB              │
│        │<────────────────────── │               │          │ (manifest URL)  │
└───┬────┘  {metadata, manifestUrl}└───────────────┘          └────────────────┘
    │
    │  1. Download manifest file (master.m3u8)
    │  2. Choose format based on bandwidth/device
    │  3. Download segments sequentially
    │  4. Adapt quality if network changes
    v
┌──────────────┐
│  S3 / CDN    │  segments: /processed/{videoId}/720p/seg_001.ts
│  (processed  │                                      seg_002.ts
│   segments)  │                                      seg_003.ts ...
└──────────────┘
```

**Adaptive bitrate streaming flow:**
1. Client fetches VideoMetadata → gets `manifestUrl`
2. Client downloads the **master manifest** (lists available formats: 1080p, 720p, 480p, 360p)
3. Client picks a format based on current bandwidth and device capabilities
4. Client downloads **segment 1** of the chosen format → starts playback immediately
5. Client prefetches upcoming segments in the background
6. If bandwidth drops → switch to a lower quality format seamlessly
7. If bandwidth improves → switch back to higher quality

---

## Full Architecture (Both Functional Requirements)

```
┌────────┐                      ┌─────────────────┐
│        │  POST /presigned_url  │                 │  getPresignedURL()
│        │─────────────────────>│                 │────────────────────┐
│        │                       │   Video Service │                    v
│ Client │  GET /videos/:videoId │                 │  store/get     ┌────────┐
│        │─────────────────────>│                 │  metadata      │  S3    │
│        │<─────────────────── │                 │───────────┐    │        │
│        │   {metadata,          └─────────────────┘           │    │ raw +  │
│        │    manifestUrl}              │                      v    │  proc. │
│        │                     ┌────────┴────────┐  ┌──────────┐   └────────┘
│        │                     │  API Gateway     │  │ Metadata │       ^
│        │                     │  - routing       │  │   DB     │       │
│        │                     │  - auth          │  └──────────┘       │
│        │                     │  - rate limiting │             ┌───────┴──────┐
│        │                     └─────────────────┘             │  Video       │
│        │                                                      │  Processing  │
│        │  Upload via presigned URL ──────────────────> S3     │  Pipeline    │
│        │  Download segments (adaptive bitrate) <────── S3/CDN │  (split +    │
└────────┘                                                      │   transcode) │
                                                                └──────────────┘
```

---

## Deep Dives

### Deep Dive 1: Video Processing Pipeline (DAG)

**Problem:** A raw uploaded video isn't streamable. It needs to be split into segments, transcoded into multiple formats, and indexed with manifest files. This is compute-heavy, parallelizable work.

**The pipeline is a DAG (Directed Acyclic Graph):**

```
┌──────────┐     ┌──────────────┐     ┌─────────────────────────────────────────────┐
│  S3 raw  │────>│ Video        │────>│  Per-segment parallel processing:           │
│  video   │     │ Splitter     │     │                                             │
│          │     │ (ffmpeg)     │     │  Segment 1 ──> Transcode 1080p ──┐          │
└──────────┘     └──────────────┘     │             ──> Transcode 720p  ──┤          │
                                      │             ──> Transcode 480p  ──┤          │
                  S3 event triggers   │             ──> Transcode 360p  ──┤          │
                  the pipeline        │             ──> Audio processing ──┤          │
                                      │             ──> Transcript gen  ──┘          │
                                      │                                             │
                                      │  Segment 2 ──> (same parallel work)         │
                                      │  Segment 3 ──> (same parallel work)         │
                                      │  ...                                        │
                                      └──────────────────────┬──────────────────────┘
                                                             │ all segments done
                                                             v
                                      ┌──────────────────────────────────────┐
                                      │  Build + store manifest files        │
                                      │  (master.m3u8 + per-quality .m3u8)   │
                                      │                                      │
                                      │  Mark video upload as "done"         │
                                      │  (update metadata DB)               │
                                      └──────────────────────────────────────┘
```

**Key points:**
- **Segment splitting** produces N independent chunks (few seconds each)
- **Transcoding** is CPU-bound and per-segment — embarrassingly parallel across worker nodes
- **Fan-out/fan-in:** split fans out to N×M parallel tasks (N segments × M formats), then fans in to build manifests
- **Orchestration:** use a DAG orchestrator (Temporal, Apache Airflow, Step Functions) to coordinate dependencies
- **Temp data in S3:** workers pass S3 URLs between steps, never pass raw bytes
- **Optimization:** some services start processing segments as they upload (pipelining), but we keep it simple — upload completes first, then process

### Deep Dive 2: Resumable Uploads (Multipart + Chunk Tracking)

**Problem:** A 10GB video upload over unstable network can fail mid-upload. Without resumability, the user starts over from scratch.

**Solution — Multipart upload with chunk tracking:**

```
┌────────┐                         ┌───────────────┐         ┌──────────────┐
│        │  POST /presigned_url     │               │ save    │  Metadata DB │
│        │ ────────────────────────>│ Upload Service│ chunks  │  VideoMeta   │
│        │<────────────────────── │               │────────>│  + chunks[]  │
│ Client │  {videoId, chunkURLs[]} └───────────────┘         │  [{hash,     │
│        │                                                    │    status}]  │
│        │  PUT chunk 1 ──────────────────> S3                └──────────────┘
│        │  PUT chunk 2 ──────────────────> S3
│        │  ❌ network fails at chunk 3
│        │
│  ...reconnect...
│        │
│        │  GET /videos/:id/chunks ─> see chunk 1,2 = Uploaded, 3+ = NotUploaded
│        │  PUT chunk 3 ──────────────────> S3  (resume from here!)
│        │  PUT chunk 4 ──────────────────> S3
│        │  ...
│        │  CompleteMultipartUpload ──────> S3 → event → processing pipeline
└────────┘
```

**Flow:**
1. Client splits the file into ~5-10MB chunks, each with a fingerprint hash
2. Client calls `POST /presigned_url` — server creates VideoMetadata with `chunks[]` (each with hash + status `NotUploaded`)
3. Client uploads each chunk to S3 via presigned URL; on S3 ACK, client notifies server → chunk status updated to `Uploaded`
4. If upload fails mid-way, client fetches chunk status → resumes from first `NotUploaded` chunk
5. After all chunks uploaded, client calls `CompleteMultipartUpload` → S3 assembles the file → triggers processing pipeline

### Deep Dive 3: Scaling to 1M Uploads / 100M Watches per Day

**Problem:** Every component must handle massive throughput. Let's analyze each:

| Component | How It Scales | Bottleneck |
|-----------|--------------|------------|
| **Video Service** | Stateless → horizontal scaling behind LB | None — just HTTP handlers |
| **Metadata DB** | Cassandra: leaderless replication, partition by `videoId` | Hot partition for viral videos |
| **Video Processing** | DAG workers with internal queue, elastic scaling | Queue depth triggers auto-scale |
| **S3** | Virtually unlimited within a region | Cross-region latency for global users |

**Two key improvements:**

**1. Metadata cache (Redis/Memcached):**
```
Client ──> Video Service ──> Cache (LRU, partitioned by videoId) ──> Cassandra
                              ↑ popular videos served from cache
                              ↑ insulates DB from hot video reads
```
Solves the "hot video" problem — a viral video's metadata is cached, so millions of reads don't hit the same Cassandra partition.

**2. CDN for video segments + manifests:**
```
Client ──> CDN edge server (geo-proximate) ──> S3 (origin)
           ↑ manifest files + segments cached at edge
           ↑ subsequent requests never reach S3
           ↑ reduces latency from 200ms → 20ms for global users
```
Popular video segments are cached at CDN edge locations worldwide. Once cached, the client streams entirely from the CDN — no backend interaction at all.

---

## Final Architecture

```
┌────────┐   get manifest/segments    ┌─────────┐  cache popular    ┌──────────┐
│        │ <─────────────────────────│   CDN   │  files from S3    │          │
│        │                            └─────────┘ <────────────────│          │
│        │                                                          │          │
│        │   upload via presigned URL ─────────────────────────────>│   S3     │
│ Client │                                                          │          │
│        │   download segments (ABR) ─────────────────────────────>│  raw +   │
│        │                                                          │  proc.   │
│        │                            ┌─────────────┐              │ segments │
│        │   POST /presigned_url      │ API Gateway  │              │ manifests│
│        │ ──────────────────────────>│ & Load       │              └─────┬────┘
│        │   GET /videos/:videoId     │ Balancer     │                    │
│        │ ──────────────────────────>│              │        S3 events   │
│        │                            └──────┬───────┘                    │
└────────┘                                   │               ┌───────────┴───────┐
                                             v               │ Upload Monitor    │
                                    ┌────────────────┐       │ (Lambda)          │
                                    │ Video Service  │       └───────────────────┘
                                    │ (N instances)  │                │
                                    └───────┬────────┘                v
                                            │               ┌────────────────────┐
                                  ┌─────────┴─────────┐     │ Video Processing   │
                                  v                   v     │ Service (DAG)      │
                           ┌──────────┐        ┌──────────┐ │                    │
                           │ Metadata │        │ Metadata │ │ Splitter → N×M     │
                           │  Cache   │───────>│   DB     │ │ Transcode workers  │
                           │ (Redis)  │  miss  │(Cassandra│ │ → Manifests → Done │
                           └──────────┘        │ /Postgres│ └────────────────────┘
                            LRU, videoId       └──────────┘
                            partition
```

---

## Additional Deep Dives (Bonus)

These are extra topics worth discussing if time allows in an interview:

### Speeding Up Uploads (Client-Side Pipelining)

Instead of waiting for the full upload to complete before processing, the **client segments the video** and uploads segments individually. The backend starts processing (transcoding) segments as they arrive — overlapping upload and processing.

**Trade-off:** Faster time-to-ready, but creates "garbage" segments if the upload is abandoned. Requires the client to do more work (segmenting + ordering).

### Resume Streaming Where User Left Off

Store `{userId, videoId, lastSegment, timestamp}` in the metadata DB or a dedicated table. When the user returns, the client fetches the last position and starts streaming from that segment.

### View Counts (Exact vs Estimated)

At YouTube scale, incrementing a counter on every view is a write bottleneck. Options:
- **Exact (write-heavy):** Increment a counter per view — simple but doesn't scale to millions of concurrent viewers
- **Estimated (batch):** Aggregate views in-memory (Redis `INCR` with periodic flush to DB), accept slight delay in counts
- **HyperLogLog:** If counting unique viewers — probabilistic data structure, O(1) memory, ~0.81% error rate

---

## Labs

Hands-on notebooks that walk through each design decision with working code.

| # | Notebook | Topic |
|---|----------|-------|
| 1 | `01_upload_videos.ipynb` | Upload flow — presigned URLs, direct-to-S3 upload, video metadata |
| 2 | `02_stream_videos.ipynb` | Streaming flow — manifest files, segment download, adaptive bitrate |
| 3 | `03_video_processing.ipynb` | Deep dive — video processing DAG, splitting, transcoding, manifest generation |
| 4 | `04_resumable_uploads.ipynb` | Deep dive — multipart upload with chunk tracking and resume |
