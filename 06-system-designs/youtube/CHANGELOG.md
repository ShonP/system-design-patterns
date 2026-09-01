# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20
- README: **added the missing capacity estimate.** The lab had functional requirements,
  non-functional requirements, a high-level design and three deep dives, but no
  back-of-envelope anywhere — in the one design in this section where the numbers *are*
  the design. Now derives the rendition-ladder cost, storage (1.28 PB/day, ~465 PB/year),
  egress (9.38 PB/day, ~868 Gbps sustained, ~2.6 Tbps peak, ~$171M/year of cloud egress),
  transcoding compute (~13,900 cores continuously), metadata, and request rates.
- README: made the central point explicit that a 4-rung ladder costs **1.8x** the 1080p
  rendition and **1.13x** the uploaded master — not 4x. Bitrate scales with pixel count,
  so the three rungs below 1080p together add only 80% to the top rung.
- README: added the honest trade-off on retaining source masters (doubles storage, but
  you need them for the next codec migration; cold storage is the compromise), and the
  observation that the request rates here are tiny (~12 uploads/sec, ~1,160 watches/sec)
  so this system's difficulty is entirely in bytes rather than QPS.
- Lab 4: the lab computed an MD5 fingerprint for every chunk, stored it in the
  metadata DB, and then never checked it against anything — while the summary table
  listed "Chunk fingerprint (MD5) — verify data integrity" as a design decision and
  relegated actual verification to "production considerations". Completion now (a)
  verifies each chunk's client-side fingerprint against the S3 ETag of that part,
  (b) downloads the assembled object and asserts a byte-for-byte SHA-256 match with
  the original, and (c) explains why the *composite* ETag of a multipart object
  (`md5(concat(part md5s))-N`) must never be compared to a whole-file MD5. Previously
  the only check was that the byte count matched.
- Lab 2: added a capacity section that **measures** the ladder against the bytes actually
  written to MinIO (1080p 17.58 MB / 720p 8.79 / 480p 3.52 / 360p 1.76 → 1.80x) rather
  than asserting the ratio, then extrapolates to the 1M uploads/day and 100M watches/day
  requirement. Placed before the cleanup cell so it weighs real objects.


## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.

## 2026-04-20
- Fixed `04_resumable_uploads.ipynb` to use current `minio-py` (7.2.x) private
  multipart API signatures: `_upload_part(bucket, object, data, headers, upload_id, part_number)`
  and `_complete_multipart_upload(..., parts: list[Part])` (the old call signatures
  crashed with a `TypeError`).
- Added a note explaining why the notebook calls minio's private multipart helpers
  (the library has no public multipart API; boto3 does).
- Verified all 4 notebooks execute end-to-end with `uv run jupyter nbconvert --execute`.
