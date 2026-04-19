# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Fixed Notebook 1 print statements that printed literal `{{video_id}}` (missing `f` prefix).
- Notebook 1 now uses `sys.executable` when starting uvicorn so the server always
  runs in the same interpreter as the notebook kernel.
- Added a new **"Don't Forget the Write Path"** section to Notebook 3 covering
  rate limiting, async write queues, moderation pipelines, and hot-video sharding.
- Added a new **"How Real Systems Do It"** section to Notebook 3 mapping the
  strategies to Facebook Live, YouTube Live, Twitch, Instagram Live, X Spaces,
  and Discord, plus a model interview answer.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
