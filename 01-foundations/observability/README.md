# Observability (Logs, Metrics, Traces)

> Part of `01-foundations/`. Pure-Python lab — no Docker required.

## Learning objectives

- Tell monitoring apart from observability.
- Explain the three pillars — metrics, logs, traces — and when to reach for each.
- Define SLI, SLO, SLA and how an error budget guides release decisions.
- Build a tiny in-memory metrics collector with counters, gauges, and histograms.

## Concepts covered

- Logs (structured, request-scoped) vs metrics (aggregate) vs traces (request flow)
- SLI, SLO, SLA, error budgets
- Counters, gauges, histograms; p50 / p95 / p99
- Mini-Prometheus implementation

## Setup

```bash
cd 01-foundations/observability
uv sync
```

Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

There are no external services — everything runs in-process.

## Notebooks

- [`notebooks/01_logs_metrics_traces.ipynb`](./notebooks/01_logs_metrics_traces.ipynb) — generate logs, metrics, and traces with stdlib only; learn when to use each.
- [`notebooks/02_sli_slo_sla.ipynb`](./notebooks/02_sli_slo_sla.ipynb) — compute an SLI from raw requests; track an error budget over 30 simulated days.
- [`notebooks/03_metrics_collector.ipynb`](./notebooks/03_metrics_collector.ipynb) — build a mini-Prometheus registry and plot a latency histogram.

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
