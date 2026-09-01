# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Checksum` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
- Added `01_no_checksum.ipynb` and `02_checksums_compared.ipynb`.
- QA pass: expanded narrative in notebook 1 (why silent corruption is worse in distributed systems), added **BLAKE2b**, a **streaming / chunked** hashing example, and a real-world systems table to notebook 2.
- Added `03_etag_and_hmac.ipynb` covering **ETag / HTTP conditional GET** and **HMAC** (with `hmac.compare_digest`, length-extension pitfall, and rotation guidance).
- Added cell `id`s to all notebooks (removes `MissingIDFieldWarning` from nbformat).
- Verified all notebooks execute end-to-end with `jupyter nbconvert --execute`.

## 2026-08-20
- Correctness audit. Added a demo that an attacker can forge a record under **every**
  algorithm here (SHA-256 and BLAKE2b included) by recomputing the digest — a checksum is not
  a MAC, and the weakness is in the *scheme*, not the hash.
- Added a birthday search that finds a CRC32 collision in ~20 ms, and an exhaustive check of
  CRC32's real guarantee (every burst error up to 32 bits detected).
- Replaced print-only checks with assertions throughout; added a "when you need this" section
  and a decision table separating checksum / MAC / signature / encryption.
