# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20
- Lab 2: rewrote the pipeline demo against a local origin server with deterministic
  failure modes (`/ok`, `/flaky` = 503 twice then 200, `/broken` = always 503).
  Exponential backoff is now shown *succeeding* on the third delivery — previously
  every URL either worked first try or went to the DLQ, so the whole point of retry
  was never demonstrated. Fixed `SimulatedQueue.receive()` mutating its list while
  iterating it (skipped messages), and fixed the stage-1 loop exiting on a poll count
  before permanently-failing messages could reach the DLQ (reported `dead letter: 0`).
  Added a re-parse pass that changes the extraction rules and proves zero re-fetching.
- Lab 3: rewritten around a local origin server that timestamps every request, so
  politeness is *measured* rather than asserted. Now shows an impolite crawler hitting
  one host at 8 req/sec vs. the same workers at 1 req/sec behind the Redis
  `SET NX PX` domain lock, and proves `Disallow: /private/` by confirming the origin
  received zero requests for it. Replaced the jitter section, which claimed a benefit
  it never measured (and printed "2/5 crawlers got through" while asserting jitter
  helped), with a no-jitter vs. jitter comparison of peak simultaneous retries and
  total Redis calls.
- Lab 3: the live robots.txt table claimed `https://www.google.com/` was allowed and
  printed ❌. Root cause: `urllib.robotparser` strips query strings from rule paths, so
  Google's `Disallow: /?` becomes `Disallow: /`. Turned this into an explicit
  "where the stdlib parser lies to you" section instead of a silently wrong table.
- README: reconciled the Bloom-filter trade-off with Lab 4 (README called it "overkill";
  the lab spends a section showing it turns 1 TB into 12 GB). Now distinguishes frontier
  seen-checks from content-hash dedup by read volume. Added the robots-parser gotcha and
  the cost-of-politeness / partition-the-frontier-by-domain trade-off.

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
