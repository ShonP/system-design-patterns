# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Observability (Metrics, Logs, Traces)` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added notebooks 01–03 (three pillars, SLI/SLO/SLA, mini metrics collector).
- **QA pass**: rewrote NB1 with a bad-vs-good logging progression and a shared `trace_id` correlation demo; expanded NB2 with vanity vs user-visible SLIs, the RED/USE methods, and a fast/slow burn-rate example; expanded NB3 with labels, a cardinality-explosion anti-pattern, and a Prometheus-style **bucketed histogram** (cumulative buckets + `_sum`/`_count` + interpolated quantiles). Replaced private `_samples` access with public accessors.
- Added NB4 `04_debugging_an_outage.ipynb` — capstone running an instrumented "checkout" service through an alert → trace → log investigation.
- Verified all four notebooks execute cleanly via `jupyter nbconvert --execute`.

## 2026-08-20 (correctness audit)
- NB3 **(new section)**: **averaging percentiles**, the single most common metrics
  mistake, was missing from the lab entirely. Added a runnable demo where the *same*
  average-of-p99s understates the true fleet p99 by 9x in one fleet and overstates it
  by 10x in another, plus the correct method (merge the histogram buckets, then take
  the quantile) and a table of what to do in Prometheus / with summaries / in an APM.
  `BucketedHistogram` gained a `merge()` so the correct method is demonstrable.
- NB1 **(new section)**: trace **sampling trade-offs** — head sampling drops the rare
  errors you actually need; tail sampling keeps all of them for the same storage bill.
- NB1: made "averages hide outliers" a measured claim rather than a sentence.
- NB2: fixed a contradiction — the notebook printed "page on-call" for a 5x burn rate
  while its own table gave the fast-burn threshold as 14.4x. Scenarios now sit
  unambiguously on either side of the Google SRE multi-window thresholds
  (14.4x / 6x / 1x), each asserted, plus a check that 14.4x for one hour really does
  burn 2% of a 30-day budget.
- NB2: the SLI demo printed a bare "❌ missed" and moved on. Added the lesson — a 99%
  SLO at a 300 ms threshold was never reachable for this latency distribution — and a
  cell that derives the tightest threshold the service can actually hold.
- NB4: fixed a real instrumentation bug — `request.end` logged
  `ms=root.duration_ms` from *inside* the span's `with` block, where it is always
  `0.0`. Added `Span.elapsed_ms()`, removed a dead `finally: pass`, and asserted that
  every `request.end` line carries a non-zero duration.
- NB4: asserted the investigation instead of narrating it — the degraded p95 breaches
  the SLO and is >3x baseline while p50 barely moves, `payments.charge` is >70% of
  every slow trace, and the log filter returns exactly the target trace's lines.
- Hygiene: kernelspec set to `Python 3 (.venv)` on all four notebooks.
