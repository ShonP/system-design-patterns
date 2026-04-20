# Lab 2: Incident Response

📖 **Exam domain**: Respond to security incidents (35–40%)

## What you'll practice

Using the mini-SIEM from Lab 1, you'll walk a realistic SOC flow end-to-end: **triage** the alert queue, **investigate** by pivoting on entities, **close** incidents properly, and **automate** response with playbooks and watchlists.

Each notebook follows a **bad → best** progression so you see *why* the SOC best practice exists, not just what it is.

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [Triage & alert correlation](notebooks/01_triage_and_correlation.ipynb) | Raw alerts → incidents via `/incidents/correlate`; prioritization by severity + confidence + blast radius + containment |
| 2 | [Entity-centric investigation](notebooks/02_entity_pivot_investigation.ipynb) | Pivot a user entity across email / sign-in / endpoint / network; reconstruct the full kill chain; auto-generate an incident report |
| 3 | [Incident lifecycle](notebooks/03_incident_lifecycle.ipynb) | Assign, comment, classify (TP/BP/FP/Undetermined), close, and tune rules |
| 4 | [Automated response & IOCs](notebooks/04_automated_response.ipynb) | Playbooks, watchlist IOC matching, containment vs eradication vs recovery, when to trust automation |

## Quick start

```bash
# 1. Start the mini-SIEM from Lab 1 (required)
cd ../01-build-a-siem && docker compose up -d

# 2. Install this lab's deps
cd ../02-incident-response
uv sync
```

Open any notebook in VS Code and pick the **`.venv` kernel** from this folder
(top-right kernel picker). If it does not appear, reload the window
(`Cmd+Shift+P` → `Reload Window`).

## Resetting state between runs

The notebooks mutate incidents, playbooks, and watchlists. They're written to be
safely rerunnable, but if you want a pristine starting point:

```bash
cd ../01-build-a-siem && docker compose down -v && docker compose up -d
```

The `-v` wipes the seeded database; the log generator then reseeds attack data.

