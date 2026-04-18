# Observability (Logs, Metrics, Traces)

> Part of `01-foundations/`. Pure-Python lab — no Docker required.

## Learning objectives

- Tell monitoring apart from observability.
- Explain the three pillars — metrics, logs, traces — and when to reach for each.
- Tell **bad logs** from **structured logs** and use a shared `trace_id` to correlate all three pillars.
- Define SLI, SLO, SLA and how an **error budget** + **burn rate** guide release decisions.
- Pick metrics with **RED** (services) and **USE** (resources); avoid the **cardinality trap**.
- Build a tiny in-memory metrics collector with counters, gauges, and **bucketed histograms** (the real Prometheus way).
- Run a full **alert → trace → log** investigation on a simulated outage.

## Concepts covered

- Logs (structured, request-scoped) vs metrics (aggregate) vs traces (request flow)
- Bad-vs-good logging; correlation via shared `trace_id`
- SLI, SLO, SLA, error budgets, fast/slow burn-rate alerts
- RED, USE, the Four Golden Signals; vanity metrics vs user-visible SLIs
- Counters, gauges, histograms; p50 / p95 / p99
- Labels, cardinality explosion, bucketed histograms vs raw samples
- Mini-Prometheus implementation
- End-to-end outage investigation

## Setup

```bash
cd 01-foundations/observability
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

There are no external services — everything runs in-process.

## Notebooks

- [`notebooks/01_logs_metrics_traces.ipynb`](./notebooks/01_logs_metrics_traces.ipynb) — generate logs, metrics, and traces with stdlib only; bad-vs-good logging; correlate the three pillars with one shared `trace_id`.
- [`notebooks/02_sli_slo_sla.ipynb`](./notebooks/02_sli_slo_sla.ipynb) — vanity metrics vs user-visible SLIs; RED & USE; compute an SLI; track an error budget over 30 simulated days; alert on **fast/slow burn rate**.
- [`notebooks/03_metrics_collector.ipynb`](./notebooks/03_metrics_collector.ipynb) — build a mini-Prometheus registry with **labels**, see the **cardinality trap**, and implement **bucketed histograms** (cumulative counts + `_sum` + `_count`) the way real systems do.
- [`notebooks/04_debugging_an_outage.ipynb`](./notebooks/04_debugging_an_outage.ipynb) — capstone: instrument a tiny "checkout" service, inject a slowdown, and walk the full **alert → trace → log** investigation loop.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
