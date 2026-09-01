# Lab 3: Threat Hunting

📖 **Exam domain**: Perform threat hunting (20–25%)

## What you'll practice

- Writing hunting queries against the mini-SIEM
- KQL patterns for common threat scenarios (with the **real** Log Analytics / Defender XDR table and column names, not the SIEM's simplified ones)
- `join` kinds, `let` / `materialize`, `arg_max`, `make-series` and the series anomaly functions
- Entity analysis and relationship mapping
- Advanced hunting query patterns
- Interpreting MITRE ATT&CK coverage — and the gaps it hides
- A self-check quiz with answers at the end of every notebook

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [KQL hunting patterns](notebooks/01_kql_hunting_patterns.ipynb) | Bad→good hunting, aggregation, rare/known-bad processes, real `SigninLogs`/`Device*` schemas, **all `join` kinds (incl. the `innerunique` default trap)**, `let`/`materialize`/`arg_max`, MITRE mapping, self-check |
| 2 | [Advanced threat hunting](notebooks/02_advanced_hunting.ipynb) | Hypothesis-driven hunts, entity pivoting, watchlists vs `ThreatIntelligenceIndicator`, hunt→detection rule, self-check |
| 3 | [Baselines & anomalies](notebooks/03_baselines_and_anomalies.ipynb) | Hour-of-day baseline, multi-signal anomaly scoring, `make-series` + `series_decompose_anomalies`, hunting maturity model, ATT&CK coverage **and gaps**, self-check |

## Quick start

```bash
cd security-certs/sc-200/03-threat-hunting
# This lab's compose file extends Lab 1's, so `up` here gives you the same
# mini-SIEM with its own copy of the database. Only one lab in this track can run
# at a time -- all three publish host port 8000.
docker compose up -d --wait
uv sync
# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/
```
