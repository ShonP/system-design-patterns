# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Netflix` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-20
- Expanded all three notebooks with bad→best progressions and runnable code.
- Notebook 1: added Python back-of-envelope calculator, Zipf popularity simulation, and
  a v1→v2→v3 architecture comparison driven by CDN cache-hit rate.
- Notebook 2: added bad→best for `watch_history` (append vs upsert vs async-batched),
  an HLS master-manifest parser, and a client-side ABR variant picker.
- Notebook 3: added a three-stage encoding benchmark (serial → parallel renditions →
  chunked+parallel), an ABR rebuffer simulation against a bumpy network profile,
  a precomputed-vs-on-demand recs benchmark, and a CDN hit-rate sensitivity table.
