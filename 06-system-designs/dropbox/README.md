# Design a File Storage Service Like Dropbox

📖 **Source**: [Hello Interview – Dropbox System Design](https://www.hellointerview.com/learn/system-design/problem-breakdowns/dropbox)

## Overview

Dropbox is a cloud-based file storage service that lets users upload, download, share, and automatically sync files across devices. Building one touches almost every system-design fundamental: blob storage, chunked transfers, metadata databases, caching, real-time sync, deduplication, and access control.

In this lab you'll implement the key pieces yourself — uploading multi-gigabyte files in resumable chunks, detecting and resolving sync conflicts, saving storage with deduplication, and enforcing sharing permissions — all with runnable Python code against real infrastructure.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Chunked File Uploads | Splitting large files into chunks, presigned URLs, resumable uploads |
| 2 | File Sync & Conflict Resolution | Polling, pub/sub notifications, version-based conflict detection |
| 3 | Deduplication | File-level & chunk-level dedup, content-defined chunking, storage savings |
| 4 | Sharing & Permissions | Access control, presigned download URLs, cache invalidation on share changes |

## Architecture

```
┌──────────┐        ┌──────────────┐        ┌───────────┐
│  Client   │──────▶│  File Service │──────▶│  Postgres  │
│ (Notebook)│       │  (our code)  │       │ (metadata) │
└─────┬─────┘       └──────┬───────┘       └───────────┘
      │                    │
      │  presigned URL     │  pub/sub
      ▼                    ▼
┌──────────┐        ┌──────────┐
│   MinIO   │       │   Redis   │
│(S3-compat)│       │  (cache   │
│  files    │       │  & sync)  │
└──────────┘        └──────────┘
```

**MinIO** acts as a local, S3-compatible blob store so you can experiment with presigned URLs, multipart uploads, and object storage without an AWS account.

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL and HTTP

## Quick Start

```bash
# Navigate to the lab directory
cd 06-system-designs/dropbox

# Start PostgreSQL + MinIO + Redis + Visualization Tools
docker compose up -d

# Install dependencies
uv sync

# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `dropbox_demo`
- **Use for**: Browse file metadata, chunk records, shared_files table

### MinIO Console (Object Storage GUI)
- **URL**: http://localhost:9001
- **Login**: Username `minioadmin`, Password `minioadmin`
- **Use for**: See uploaded file chunks, browse the `dropbox-files` bucket

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch pub/sub messages, inspect cached share lists

## Key Concepts Covered

### Chunked Uploads & Presigned URLs
- Why single-request uploads fail for large files
- Splitting files into chunks with SHA-256 fingerprints
- Presigned URLs: letting clients upload directly to object storage
- Tracking chunk progress in Postgres for resumable uploads

### File Sync & Conflict Resolution
- Local → Remote sync via change detection
- Remote → Local sync via polling and pub/sub (Redis)
- Version-based conflict detection
- Resolution strategies: last-write-wins vs keep-both

### Deduplication
- File-level dedup: skip uploads when fingerprint already exists
- Chunk-level dedup: share storage across partially-similar files
- Content-Defined Chunking (CDC) vs fixed-size chunking
- Reference counting for safe deletion

### Sharing & Permissions
- Normalized `shared_files` table for fast "shared with me" queries
- Presigned download URLs with expiry for secure sharing
- Permission checks (read vs write)
- Cache invalidation when shares change

## What This Lab Does *Not* Do

These notebooks are deliberately small. Where the toy diverges from the real system:

| Toy version | Real Dropbox |
|---|---|
| Chunk boundaries from a 32-bit shift-and-add rolling hash | Rabin fingerprint over GF(2), tuned for boundary distribution |
| Sync notifications over Redis Pub/Sub (fire-and-forget, no replay) | Long-poll / WebSocket notification service with durable cursors |
| Conflict detection via a single `version` integer per file | Per-namespace journal cursors, server-side merge for some types |
| Deletion by direct refcount query at delete time | Asynchronous garbage collection over a refcount store |
| Whole-file re-upload on edit | Block-level delta sync — only changed 4 MB blocks move |
| Presigned URLs signed by the notebook itself | A metadata service that authorises, then signs |

The MinIO bucket is created **private** (`mc anonymous set none`). Notebook 4 checks this
before it claims presigned URLs are what grants access — if the bucket were world-readable,
every access control in the lab would be decorative.

## Real-World Parallels

| Concept | How Dropbox Actually Does It |
|---------|------------------------------|
| Chunked uploads | S3 Multipart Upload API, 4 MB chunks |
| Deduplication | Content-Defined Chunking saves ~25% storage |
| Sync | Desktop client watches filesystem events (FSEvents / inotify) |
| Conflict resolution | Keeps "conflicted copy" with device name + timestamp |
| Sharing | ACL table + signed URLs with short TTL |

## License

Educational content — feel free to use and modify for learning purposes.
