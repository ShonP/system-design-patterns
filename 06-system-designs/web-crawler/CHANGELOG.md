# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Lab 2: fixed the fetch-stage demo — exponential backoff (2s/4s/8s) is now
  actually applied (scaled 10×) instead of a hardcoded 0.1s, and the loop waits
  long enough for permanently-failing URLs to reach the DLQ. Demo now shows
  two messages landing in the DLQ after 3 retries each.
- Lab 3: replaced `RobotFileParser.read()` (which uses Python's default urllib
  User-Agent and gets 403s from Google/Wikipedia/Twitter) with a `requests`-based
  fetch + `rp.parse()`. robots.txt permissions for real sites are now correct
  (e.g. Google `/search` disallowed, Wikipedia articles allowed).
- Lab 4: fixed crawler-trap demo so the depth limit actually trips (was hitting
  a 30-page cap first, reporting `Skipped: 0`). Added a Bloom-filter section
  with a tiny hand-rolled implementation demonstrating ~10 bits/item and ~1%
  false-positive rate — explains how to dedup 10B URLs in ~12 GB instead of 1 TB.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
