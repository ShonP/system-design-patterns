# Checksum

> Part of `02-distributed-primitives/`. Hands-on lab that builds up from "no checksum = silent corruption" to real-world patterns like **ETag** and **HMAC**.

## Learning objectives

- See *why* untrusted bytes lead to silent corruption in distributed systems.
- Distinguish CRC32 (error detection) from cryptographic hashes (MD5, SHA-256, BLAKE2b) and know when each one is appropriate.
- Checksum large files with a **streaming** API.
- Use a checksum as an **ETag** to skip unchanged HTTP responses.
- Use **HMAC** to detect *malicious* tampering, not just accidents.

## Concepts covered

- Silent corruption and why it is so dangerous with replication / backups
- CRC32 vs MD5 vs SHA-256 vs BLAKE2b — speed vs strength trade-off
- Chunked / streaming hashing for files that don't fit in RAM
- ETag and HTTP conditional GET (`If-None-Match` / `304 Not Modified`)
- HMAC and why `hmac.compare_digest` matters
- End-to-end integrity, and where real systems (ZFS, Kafka, Postgres, Git, S3, TLS) sit on these trade-offs

## Setup

```bash
cd 02-distributed-primitives/checksum
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_no_checksum.ipynb`](./notebooks/01_no_checksum.ipynb) — silent corruption when bytes are trusted blindly.
- [`notebooks/02_checksums_compared.ipynb`](./notebooks/02_checksums_compared.ipynb) — CRC32 vs MD5 vs SHA-256 vs BLAKE2b; round-trip, corruption detection, streaming, and performance.
- [`notebooks/03_etag_and_hmac.ipynb`](./notebooks/03_etag_and_hmac.ipynb) — ETag-based HTTP conditional GET and HMAC for tamper-proof messages.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
