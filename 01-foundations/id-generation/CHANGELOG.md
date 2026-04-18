# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Distributed ID Generation` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added Notebook 1 (`01_why_id_generation_is_hard.ipynb`): BAD/BETTER/BEST progression with B-tree locality demo.
- Added Notebook 2 (`02_uuid_ulid_ksuid_compared.ipynb`): from-scratch UUIDv4/v7, ULID, KSUID + monotonic ULID + pydantic validator.
- Added Notebook 3 (`03_snowflake_id_generator.ipynb`): 64-bit Snowflake generator with sequence-overflow and clock-skew handling.
- QA pass: verified all notebooks execute end-to-end.
- Added Notebook 4 (`04_production_patterns.ipynb`): worker-ID assignment, DB storage trade-offs, decoding a real Discord snowflake, NanoID, production gotchas.
- Updated Notebook 2 cheat sheet to mention NanoID.
