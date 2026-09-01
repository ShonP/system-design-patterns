# Distributed ID Generation

📖 **Source**: [DesignGurus — Grokking Scalable Systems & Grokking System Design Interview II](./references/designgurus.md)

## Overview

Every record in a database needs a unique identifier — a user ID, an order ID, a tweet ID.
With one database it's easy (`id SERIAL PRIMARY KEY`). With **many servers** generating IDs at the same time, it gets interesting.

This lab walks through the classic progression **single-DB auto-increment → UUIDv4 → time-ordered IDs (UUIDv7 / ULID / KSUID / Snowflake)** and implements each format from scratch in plain Python so nothing feels like magic.

## Learning objectives

- Compare UUID, ULID, KSUID, and Snowflake on uniqueness, sortability, and size.
- Understand Snowflake's `timestamp + worker + sequence` structure and its clock-skew pitfalls.
- See why random primary keys hurt B-tree index locality (with a tiny demo).
- Build intuition for coordination-free ID generation in distributed systems.

## Notebooks in this series

| # | Notebook | What you'll learn |
|---|----------|-------------------|
| 1 | [`01_why_id_generation_is_hard.ipynb`](notebooks/01_why_id_generation_is_hard.ipynb) | Auto-increment bottleneck, UUIDv4 randomness, B-tree locality — **BAD → BETTER → BEST** |
| 2 | [`02_uuid_ulid_ksuid_compared.ipynb`](notebooks/02_uuid_ulid_ksuid_compared.ipynb) | Implement UUIDv4, UUIDv7 (RFC 9562), ULID, and KSUID from scratch |
| 3 | [`03_snowflake_id_generator.ipynb`](notebooks/03_snowflake_id_generator.ipynb) | Build a Snowflake generator: bit layout, sequence overflow, and a clock rewind that makes the unguarded version emit **duplicate IDs** before we fix it |
| 4 | [`04_production_patterns.ipynb`](notebooks/04_production_patterns.ipynb) | Worker-ID strategies, DB storage, decoding a real Discord snowflake, NanoID, gotchas |

## Prerequisites

- Python 3.10+
- [uv](https://docs.astral.sh/uv/) for dependency management
- No Docker, no database — this lab uses only the Python standard library + `pydantic`

## Setup

```bash
# From the repo root
cd 01-foundations/id-generation

# Install dependencies into a local .venv
uv sync

# Open any notebook in VS Code and select the .venv kernel
#   (kernel picker is top-right of the notebook)
```

### If the `.venv` kernel doesn't appear in VS Code

Reload the window: `Cmd+Shift+P` → **"Reload Window"**.
VS Code should then detect the new interpreter.

## Key concepts covered

- UUID v4, UUID v7 (RFC 9562), ULID, KSUID, Snowflake, NanoID
- Monotonic vs wall-clock time; clock skew
- Time-ordered IDs and B-tree index locality
- Coordination-free ID generation
- Worker-ID assignment strategies (env var, hostname hash, k8s ordinal, coordinator)
- Database storage: native `uuid`/`BIGINT` columns vs strings
- Decoding real-world snowflakes (Discord/Twitter)

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`CHANGELOG.md`](./CHANGELOG.md) — what changed and when
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping

## License

Educational content — feel free to use and modify for learning purposes.

