# 📁 Handling Large Blobs

Learn how to handle large files (videos, images, documents) in distributed systems without bottlenecking your servers.

## The Problem

Large files don't belong in databases or flowing through your API servers. A 2GB video upload that passes through your server wastes bandwidth, adds latency, and creates bottlenecks.

```
❌ BAD: Server as Proxy
┌────────┐    ┌────────────┐    ┌─────────────┐
│ Client │───>│ API Server │───>│ Blob Storage│
│  2GB   │    │ (Bottleneck)│   │             │
└────────┘    └────────────┘    └─────────────┘

✅ GOOD: Direct Upload with Presigned URLs  
┌────────┐    ┌────────────┐
│ Client │───>│ API Server │ "Can I upload?"
└────────┘    └─────┬──────┘
     │              │
     │   ┌──────────▼──────────┐
     │   │ "Here's a presigned │
     │   │  URL, upload there" │
     │   └─────────────────────┘
     │
     ▼ Direct upload (2GB)
┌─────────────┐
│ Blob Storage│
└─────────────┘
```

## What You'll Learn

| Notebook | Topic | Key Concepts |
|----------|-------|--------------|
| 01 | The Proxy Problem | Why proxying hurts, bandwidth costs |
| 02 | Presigned URLs | Direct upload/download, security |
| 03 | Resumable Uploads | Multipart uploads, chunk tracking |
| 04 | State Sync | Metadata management, event notifications |
| 05 | Download Optimization | Range requests, parallel downloads |
| 06 | Security & Abuse | Content validation, quarantine pattern |

## Decision Flowchart

```
File size?
├── < 10MB → Regular API upload
└── > 10MB → Use this pattern
    │
    ├── Need real-time validation? → Proxy (but in chunks)
    │
    └── Can validate async? → Direct upload
        │
        ├── File > 100MB? → Multipart/resumable
        │
        └── Frequent downloads? → Add CDN
```

## Quick Start

```bash
# Start MinIO (S3-compatible) and PostgreSQL
docker compose up -d

# Install dependencies
pip install -r requirements.txt

# Open notebooks in order
```

## Services

| Service | URL | Credentials |
|---------|-----|-------------|
| MinIO Console | http://localhost:9001 | minioadmin / minioadmin |
| MinIO API | http://localhost:9000 | - |
| PostgreSQL | localhost:5432 | postgres / postgres |
| Adminer | http://localhost:8080 | postgres / postgres / largeblobs |

## Real-World Applications

- **YouTube**: Video uploads via presigned URLs, multipart for large files
- **Instagram**: Photo uploads bypass API servers entirely
- **Dropbox**: Chunked uploads with resume capability
- **WhatsApp**: Media sharing with expiring signed URLs
