# Distributed ID Generation

> Part of `01-foundations/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Learning objectives

- Compare UUID, ULID, KSUID, and Snowflake IDs on uniqueness, sortability, and size.
- Understand Snowflake's timestamp + worker + sequence structure and its clock-skew pitfalls.
- Know the difference between wall-clock time and monotonic time and why clock skew is a real-world problem.

## Concepts covered

- UUID v1/v4/v7, ULID, KSUID, Snowflake
- Monotonic vs wall-clock time; clock skew
- Time-ordered IDs and index locality
- Coordination-free ID generation

## Planned notebooks

> These are planned; files do not yet exist. Following the repo convention, each will be added as a separate numbered notebook (`NN_*.ipynb`) without renumbering earlier ones.

- `notebooks/01_id_format_comparison.ipynb`
- `notebooks/02_snowflake_from_scratch.ipynb`
- `notebooks/03_clock_skew_and_monotonic_time.ipynb`

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
