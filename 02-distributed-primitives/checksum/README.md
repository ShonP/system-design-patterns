# Checksum

> Part of `02-distributed-primitives/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Learning objectives

- Distinguish CRC (error-detection) from cryptographic hashes (integrity + tamper detection).
- Use checksums to detect bit-rot in stored data and in transit.

## Concepts covered

- CRC vs MD5/SHA
- ETag and HTTP conditional requests
- End-to-end integrity

## Setup

```bash
cd 02-distributed-primitives/checksum
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_no_checksum.ipynb`](./notebooks/01_no_checksum.ipynb) — silent corruption when bytes are trusted blindly.
- [`notebooks/02_checksums_compared.ipynb`](./notebooks/02_checksums_compared.ipynb) — CRC32 vs MD5 vs SHA-256 — detection, performance, when to use each.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
