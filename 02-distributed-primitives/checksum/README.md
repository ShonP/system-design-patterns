# Checksum

> Part of `02-distributed-primitives/`. Hands-on lab that builds up from "no checksum = silent corruption" to real-world patterns like **ETag** and **HMAC**.

## Learning objectives

- See *why* untrusted bytes lead to silent corruption in distributed systems.
- Distinguish CRC32 (error detection) from cryptographic hashes (MD5, SHA-256, BLAKE2b) and know when each one is appropriate.
- See a CRC32 collision found in milliseconds, and a forged record accepted under *every* algorithm — including SHA-256 — because a checksum is not a MAC.
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

## When you need this — and when you don't

**Use a checksum when** bytes cross a boundary you don't control: disk, network, a queue, a
backup bucket, a process restart. Anywhere corruption would otherwise be *silent*, a few bytes
of digest turn a wrong answer into a loud error.

**Pick CRC32 when** you are guarding against hardware faults and want it to be free. It detects
every 1-bit error and every burst up to 32 bits — guarantees, not probabilities.

**Pick SHA-256/BLAKE2b when** the digest also *names* something (content addressing, dedup,
cache keys), because a 32-bit value collides after ~65,000 items.

**A checksum is the wrong tool when** the threat is a person rather than a cosmic ray. Notebook 2
forges a "valid" record under every algorithm here, SHA-256 included, because the attacker can
rewrite the digest too. You need a key: HMAC (notebook 3) or a signature.

**Skip it when** the layer beneath you already verifies end-to-end *and* you trust it to fail
loudly — but note TCP's checksum is 16 bits and does not cover the application, so "TCP handles
it" is usually wrong.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
