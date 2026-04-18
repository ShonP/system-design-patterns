# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18 (QA pass)
- **Fix**: bind-mount `./origin/assets` into the origin container so notebook 3's "stale demo" (host edits → origin serves new bytes) actually works. Previously assets were baked into the image at build time.
- **Fix**: implement explicit `If-None-Match` handling in `origin/main.py` so the origin returns a real `304 Not Modified` (empty body, no artificial delay) when the client's ETag matches. Previously Starlette's stat-based default ETag conflicted with our md5 ETag and `304` was never returned.
- **Add**: `notebooks/04_real_world_pitfalls.ipynb` covering cache stampede / `proxy_cache_lock`, stale-while-revalidate / `proxy_cache_use_stale`, the `Vary` header, the `Cache-Control` directive cheat-sheet, and the classic "caching authenticated responses" security bug.
- All four notebooks executed end-to-end against the docker-compose stack to verify they run without errors.

## 2026-04-18
- Scaffolded `Content Delivery Networks (CDN)` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
