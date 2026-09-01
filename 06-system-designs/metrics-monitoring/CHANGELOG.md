# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-21 (content-correctness review)

**Defects fixed**

- **NB2: the alert state machine never reached `firing`.** The evaluation-loop demo ran 3
  iterations 10s apart against seeded rules whose `for` durations are 60-300s, so it could
  only ever print "pending" — the notebook's central lesson never actually happened. The loop
  now drives the same code path from a scripted value sequence with a short `for`, walks
  inactive → pending → firing → resolved in ~8 seconds, and asserts that sequence.
- **NB1: the simulator could not breach its own alert thresholds.** CPU was
  `40 + 25*sin(t/20) ± 10`, capped at 75%, so `HighCpuUsage` (>80) and `CriticalCpuUsage`
  (>95) in `alert_rules.yml` were permanently inactive. Retuned the CPU sine and the memory
  sawtooth so `HighCpuUsage` and `HighMemoryUsage` genuinely fire (~155s and ~125s above
  threshold per cycle, against `for: 1m`), and documented which rules are deliberately rare.
- **NB2: alert grouping silently downgraded critical alerts.** `max(e["severity"] ...)` took
  the max of raw *strings*, and "warning" > "critical" alphabetically — a group holding 5
  critical alerts paged as a warning. Replaced with an explicit severity rank plus an
  assertion that the us-east group stays critical.
- **NB1/NB3: three markdown cells were structurally corrupted** (empty `##` headers, table
  cells swapped across the pipe, sentences with clauses transposed — e.g. "Saturation leads
  it's how you catch problems before they cause errors.latency"). Rewritten: the cardinality
  section in NB1, the Four Golden Signals section in NB3, and the Real-World Examples header.
- **NB3: prose contradicted its own printed table by 10×.** The step-size cell printed
  259,200 points for a 30-day chart at 10s step, while the text below claimed "2.6M points".
  Numbers are now computed rather than typed, with an assertion.
- **NB1: the rollup table was internally inconsistent.** A column headed "Points per series
  (30 days)" mixed retention-window counts (raw: 17,280 = 2 days) with 30-day counts
  (1-minute: 43,200, despite a 2-week retention). Split into two honest columns.
- **NB1: "Time-series DBs have built-in downsampling" is false for Prometheus.** Vanilla
  Prometheus has no rollups at all — that is precisely what Thanos/Cortex/Mimir add, as NB3's
  own Real-World table says. Corrected, with a note.
- **NB1: `rate()` prose was off by one.** `counter[-1] - counter[0]` across 10 samples was
  described as "total over 10 intervals"; it spans 9. Now computes and labels the rate correctly.
- **NB3: the query-splitting demo double-counted its boundary sample.** Prometheus range
  queries are inclusive of both endpoints, so the historical and fresh halves both returned
  the sample at `split_point`. Fresh half now starts one step later; asserted.
- **NB3 / `alert_rules.yml`: latency was described as a percentile but measured as a mean.**
  The `HighLatency` rule's description claimed "p50 latency above 2s" while watching a gauge
  whose help text says "Average request latency". Renamed to `HighAvgLatency`, description
  corrected, and the correct histogram-based expression documented alongside it.
- **NB1: the Postgres write benchmark was rigged.** 10,000 row-at-a-time `INSERT`s were used
  to conclude "Postgres can't sustain that write throughput", which measured network round
  trips. Now measures batched `execute_values` as well and states the real, structural reasons
  metrics platforms don't use an OLTP row store.
- **NB3: `avg(demo_error_rate)` averaged unweighted per-host percentages.** Replaced on the
  RED panel and in the provisioned Grafana JSON with a ratio of rates
  (`sum(rate(5xx)) / sum(rate(total))`), with the naive number printed beside it for contrast.
- **NB3: the API-created Grafana dashboard had no `uid`**, so `overwrite: True` did nothing and
  every re-run accumulated a duplicate. Added a stable uid.

**Determinism (second pass — the lab was intermittently failing)**

The first pass introduced two wall-clock races. Both are fixed at the mechanism, not by
relaxing the assertion:

- **NB2: the alert-lifecycle demo slept for real.** It advanced a 5-second `for` timer with
  `time.sleep()`, so a 2-second stall on a loaded machine skipped a state and the sequence
  assertion failed — roughly one run in two under parallel Docker load. The evaluator now
  takes its evaluation timestamp as an injected parameter (`now=`), exactly as Prometheus
  passes one into `Rule.Eval` so a group evaluates as of a single consistent instant. The
  demo drives it with a virtual clock and a scripted value sequence: no sleeping at all, the
  whole lifecycle is a chain of pure calls, and the assertion is now an exact state sequence
  rather than an approximate one. Runs in under a millisecond.
- **NB2: added a second scripted case** now that cases are free — a breach interrupted by one
  clean evaluation. It shows the metric over the threshold at 5 of 7 evaluations and still
  never paging anyone, which is the `for:` semantics people get wrong. Asserted.
- **NB3: the query-split cache could never reliably hit.** The cache key was derived from a
  raw `time.time()`, so it changed every second and two calls that straddled a second boundary
  addressed different entries — the printed "Query 2: 🟢 HIT" was a coin flip, and the
  assertion on it inherited that. Windows are now aligned down onto the step grid and the
  demo pins one `to` timestamp across all three calls, which is both what Grafana and Mimir's
  query-frontend actually do and what makes the demo exact. The historical half's TTL went
  from 60s to 300s (it is immutable for a pinned window, so the short TTL bought nothing).
- **NB1: the Redis cache demo raced its own TTL.** Three round trips inside a 15-second window
  is a race on a busy machine; the demo now passes an explicit 300s TTL.
- **NB1: replaced `time.sleep(15)` "wait for Prometheus to scrape"** with `wait_for_series()`,
  a bounded poll (90s) for the data the following cells actually need. A guessed constant meant
  the PromQL section sometimes printed nothing and looked broken.

**Added**

- **NB1: a new section on the two ways percentiles go wrong**, with a seeded, offline,
  fully-asserted demo. It shows (a) averaging three instances' p99s reports 1.72s when the
  true fleet p99 is 3.05s — a 44% under-report — and (b) a reimplementation of Prometheus'
  `histogram_quantile()` measured against known truth: client-library default buckets land
  46% high because they jump 2.5s → 5.0s, a layout whose highest finite bucket is 1s returns
  exactly 1.000s forever, and SLO-tuned buckets land within 1%.
- **NB1: a real `Histogram`** (`demo_request_duration_seconds`, 15 explicit buckets). The
  notebook had promised percentiles and `histogram_quantile()` since its metric-types table
  but only ever exposed gauges. The latency gauge now holds the mean of the same observation
  batch, matching its help text.
- **NB3: a p99-vs-average latency comparison** on the RED panel and in the provisioned
  dashboard, aggregating `_bucket` series with `sum by (le)` *before* taking the quantile.
  The simulator's average latency sits near 0.45s while its p99 is close to 4s.
- **NB1: a note on sizing `rate()` windows** (≥ 4× the scrape interval) and on counter-reset
  handling, and why that makes `rate()` wrong for gauges.
- **NB2: an explanation of what `for:` actually means** — true at *every* evaluation, not on
  average; one false evaluation resets the timer to zero.
- **README: a "What This Lab Does NOT Do" section** (no Alertmanager, no long-term storage or
  downsampling, no HA/sharding/remote-write) and the percentile pitfall under Common Problems.
- **Assertions throughout**, so the lab fails loudly if it stops reproducing its own lesson:
  counter monotonicity and tail-ratio (NB1), the percentile and bucket-resolution errors
  (NB1), batching beating row-at-a-time inserts (NB1), Redis cache MISS/HIT/HIT (NB1, NB3),
  the full alert lifecycle and pending-held-more-than-one-tick (NB2), exactly two
  notifications escaping dedup+silencing (NB2), grouped severity escalation (NB2), polling
  detection latency ≈ interval/2 (NB2), and the split-query point budget (NB3).
- Seeded every RNG used for a printed claim (NB1 metric types and percentile demo, NB1 write
  benchmark, NB2 detection-latency simulation).

## 2026-08-20 (repo-wide verification pass)
- **Fix**: repaired a source line in notebook 3 that had lost its trailing newline, concatenating two statements.
- Note: Grafana publishes on host port **3000**, which commonly collides with a local dev server. Run `python tools/check_ports.py 06-system-designs/metrics-monitoring` if the stack will not start.

## 2026-04-20
- Fixed `psycopg2.cursor(RealDictCursor)` bug in notebooks 02 and 03 (positional arg → `cursor_factory=` kwarg). Without the fix the cells crashed on first run.
- Made the NB1 metrics HTTP server cell idempotent so re-running it stops the previous server instead of raising `OSError: [Errno 48] Address already in use`.
- Made the NB2 alert-event demo cell idempotent (`TRUNCATE alert_events` before inserting) so re-runs produce the same result instead of piling up rows.
- Added a **cardinality explosion** concept + runnable demo to NB1 showing how `user_id` or `request_id` labels blow up series count and TSDB memory.
- Added the **Four Golden Signals** (Google SRE: Latency, Traffic, Errors, Saturation) to NB3 alongside the existing USE/RED methods.
- Added a **Real-World Examples** table to NB3 (Uber M3, Netflix Atlas, Thanos, Datadog, Grafana Mimir) with the common patterns they all share.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
