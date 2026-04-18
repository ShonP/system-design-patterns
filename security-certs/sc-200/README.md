# SC-200: Microsoft Security Operations Analyst

📖 **Source**: [SC-200 Study Guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/sc-200)

## What is SC-200?

SC-200 is the **Security Operations Analyst** certification. While SC-900 teaches concepts and AZ-500 teaches configuration, SC-200 is about **operating** a SOC — triaging alerts, investigating incidents, hunting threats, and writing KQL queries.

**This lab is different**: instead of just reading about Sentinel, we **build a working mini-SIEM** from scratch. You'll implement the same core components that Sentinel uses — log ingestion, a KQL-like query engine, analytics rules, alert correlation into incidents, and automated playbooks — then use it hands-on.

## Exam domains → Labs

| Domain | Weight | Lab | What you'll build & practice |
|--------|--------|-----|------------------------------|
| Manage a SOC environment | 40–45% | [01-build-a-siem](01-build-a-siem/) | Build a mini-SIEM: log ingestion, analytics rules, data connectors, MITRE mapping |
| Respond to incidents | 35–40% | [02-incident-response](02-incident-response/) | Alert correlation, incident investigation, triage workflows, automated response |
| Perform threat hunting | 20–25% | [03-threat-hunting](03-threat-hunting/) | KQL deep dive, hunting queries, entity analysis, attack pattern detection |

## Architecture — what you're building

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Log Sources │     │  Log Sources │     │  Log Sources │
│  (Entra ID)  │     │  (Firewall)  │     │  (Endpoint)  │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │
       └────────────┬───────┘────────────────────┘
                    ▼
         ┌──────────────────┐
         │  Data Connectors  │  ← Ingest + normalize logs
         │  (REST API)       │
         └────────┬─────────┘
                  ▼
         ┌──────────────────┐
         │  Log Store        │  ← SQLite tables (like Log Analytics)
         │  (Query Engine)   │  ← KQL-like query language
         └────────┬─────────┘
                  ▼
         ┌──────────────────┐
         │  Analytics Rules  │  ← Scheduled queries that fire alerts
         │  (Detection)      │  ← MITRE ATT&CK mapping
         └────────┬─────────┘
                  ▼
         ┌──────────────────┐
         │  Alert Correlator │  ← Group alerts into incidents
         │  (Incidents)      │  ← Entity extraction
         └────────┬─────────┘
                  ▼
         ┌──────────────────┐
         │  Automation       │  ← Playbooks (automated response)
         │  (Playbooks)      │  ← Webhook triggers
         └──────────────────┘
```

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Completed [SC-900 labs](../sc-900/) or equivalent knowledge

## Quick start

```bash
cd security/sc-200/01-build-a-siem

# Start the mini-SIEM + log generators
docker compose up -d

# Install dependencies
uv sync
uv run python -m ipykernel install --user --name=sc-200 --display-name="SC-200 (Python)"
```

Then open the notebooks and select the `SC-200 (Python)` kernel.
