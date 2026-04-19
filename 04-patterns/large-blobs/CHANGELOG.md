# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19
- Fixed notebook 5 (download optimization): presigned URLs signed for `get_object` don't permit `HEAD`, so the original `requests.head()` calls returned `Content-Length: 0`. The resumable and parallel downloaders now learn the total size via a 1-byte `Range: bytes=0-0` probe and read `Content-Range`. This also fixes the parallel demo's data-integrity mismatch.
- Added to notebook 3: a "Cleaning Up Abandoned Multipart Uploads" section that uses `list_multipart_uploads` + `abort_multipart_upload` and explains lifecycle rules.
- Added to notebook 6: a magic-byte content-validation demo that catches a file claiming `image/jpeg` but actually starting with the Windows-exe (`MZ`) header.
- README: updated notebook summary to reflect the new content.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
