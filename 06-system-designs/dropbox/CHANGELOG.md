# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.

## 2026-04-20
- Fixed incorrect "Next notebook" cross-references in notebooks 1, 2, 3 summaries (they had been written in the wrong order after the series was reordered).
- Fixed final summary table in notebook 4 that mislabelled notebooks 2 and 3.
- Corrected `cd system-designs/dropbox` → `cd 06-system-designs/dropbox` in README and all notebook setup cells.
- Added missing `requests` dependency to `pyproject.toml` (used by notebooks 1 and 4 for presigned URL HTTP PUT/GET).
- Verified every notebook executes top-to-bottom against the docker-compose stack with no errors.
