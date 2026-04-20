# Lab 1: Build a SIEM — Hands-on Security Operations

📖 **Exam domain**: Manage a security operations environment (40–45%)

## What you'll build

Instead of reading about Sentinel, you'll **build one**. The mini-SIEM implements:

- **Data connectors** — REST API that ingests logs from multiple sources
- **Log tables** — SigninLogs, AzureFirewall, DeviceEvents, EmailEvents
- **Query engine** — filter, aggregate, time-window queries (KQL-like)
- **Analytics rules** — scheduled detections with MITRE ATT&CK mapping
- **Alert correlation** — group related alerts into incidents
- **Playbooks** — automated response triggered by severity/tactic

## Architecture

The mini-SIEM is a FastAPI service backed by SQLite. A log generator produces realistic attack patterns (brute force, lateral movement, phishing, data exfiltration).

## Notebooks

| # | Notebook | What you'll do |
|---|----------|----------------|
| 1 | [Data ingestion and connectors](notebooks/01_data_ingestion.ipynb) | Ingest logs, explore tables, understand data connector patterns |
| 2 | [Analytics rules and detection](notebooks/02_analytics_rules.ipynb) | Create detection rules, map to MITRE ATT&CK, evaluate against data |
| 3 | [Incidents and automation](notebooks/03_incidents_and_automation.ipynb) | Correlate alerts, investigate incidents, run playbooks |

## Quick start

```bash
cd security-certs/sc-200/01-build-a-siem
docker compose up -d          # start the mini-SIEM + seed attack data
uv sync                       # install notebook dependencies
```

Open any notebook in VS Code and pick the **`.venv` kernel** from this folder
(top-right kernel picker). If it does not appear, reload the window
(`Cmd+Shift+P` → `Reload Window`).

The log generator automatically seeds the SIEM with normal traffic + attack patterns. Open any notebook and you'll have real data to investigate.

## Troubleshooting

| Symptom | Fix |
|--------|-----|
| `ConnectError` on `localhost:8000` | Run `docker compose up -d`, then `docker compose ps` to confirm `sc200-siem` is **healthy**. |
| Dashboard shows `total_logs: 0` | Wait ~10 seconds for the log generator to finish, or run `docker logs sc200-log-generator`. |
| Want to start fresh | `docker compose down -v && docker compose up -d` — the `-v` wipes the seeded database. |
| Notebook kernel missing | Re-run `uv sync`; pick the `.venv` kernel; reload the VS Code window. |
