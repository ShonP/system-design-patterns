# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

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
