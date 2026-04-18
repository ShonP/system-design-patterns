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
