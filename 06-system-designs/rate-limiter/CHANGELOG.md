# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20
- `app/server.py`: **fixed `Retry-After`.** It returned `max_tokens / refill_rate`
  (10s on the default rule) when the true wait for one token is ~1s — telling every
  rejected client to idle 10x longer than needed. Now returns
  `ceil((1 - tokens) / refill_rate)`. `X-RateLimit-Reset` was likewise a constant
  `now + 10` regardless of bucket state; it now tracks time-to-full.
- `app/server.py`: the Lua script took `now` from the caller, so a gateway with a fast
  clock refilled every bucket it touched. Now reads `redis.call('TIME')` inside the
  script, making the timeline server-authoritative. Also `HMSET` -> `HSET`, catch
  `redis.RedisError` rather than only `ConnectionError`, and added socket timeouts.
- `app/server.py`: fail-open vs fail-closed is now an explicit `RATE_LIMIT_FAIL_MODE`
  env var (default `open`) with `X-RateLimit-Degraded` on degraded responses. The code
  silently failed *closed* while Lab 3 told readers "most teams choose fail open".
- Lab 1: fixed `LeakyBucket._leak()` discarding the fractional remainder when advancing
  `last_leak` to `now`, which made the bucket drain slower than its configured rate.
- Lab 2: both boundary demos printed their conclusion ("10 requests allowed in ~0.3s")
  as a hardcoded string regardless of what happened. They now count the requests,
  report the overshoot as a multiple of the limit, and assert the 2x burst reproduced.
  Added an honest note that the sliding window is an approximation and still leaked one
  request in this test.
- Lab 3: the race-condition demo raced a hand-instrumented copy with an artificial
  `sleep(0.01)`, not the `simple_rate_limit()` it had just called buggy. Now races the
  real function with 30 threads and no staging — reproduces 12-18 allowed against a
  limit of 10, every run. The atomic test now runs the identical load for a direct
  comparison.
- Lab 3: added a clock-skew section — demonstrates a gateway with a 60s-fast clock
  refilling an empty bucket, then fixes it with `redis.call('TIME')`, with the
  replication/sharding trade-off spelled out.
- Lab 4: the 429 section printed headers without checking them. It now verifies
  `Retry-After` is honest: retrying immediately still 429s, retrying after exactly
  `Retry-After` seconds succeeds.
- README: added Functional / Non-Functional requirements and a capacity estimate
  (1M req/sec -> 16 Redis shards; 100M clients x 3 rules x 150 B -> 45 GB; why the
  check must be a single round-trip). Reconciled the fail-open contradiction between
  Lab 3, Lab 4 and the server code.

## 2026-04-20
- Notebook 1: added **Leaky Bucket** section with runnable demo comparing Leaky vs Token Bucket behavior on bursts.
- Notebook 2: added **Sliding Window Log** implementation (exact accuracy at higher memory cost) — previously only mentioned in the README.
- Notebook 4: added **Tiered Limits** demo (free vs premium endpoint burst) and a **client-side exponential-backoff retry** example with jitter.
- `app/server.py`: middleware now maps `/api/premium` to the `premium` rule (it was silently using `default`). Added `NoScriptError` fallback so rate limiting still works after a Redis restart flushes the script cache.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
