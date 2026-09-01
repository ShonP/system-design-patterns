# Lab 2: Incident Response

📖 **Exam domain**: Respond to security incidents (35–40%)

## What you'll practice

Using the mini-SIEM from Lab 1, you'll walk a realistic SOC flow end-to-end: **triage** the alert queue, **investigate** by pivoting on entities, **close** incidents properly, and **automate** response with playbooks and watchlists.

Each notebook follows a **bad → best** progression so you see *why* the SOC best practice exists, not just what it is, and ends with a **self-check quiz plus answers**.

> `notebooks/build_notebooks.py` is the original generator for these notebooks. The committed
> notebooks have since been hand-edited, so treat the script as reference only — re-running it
> would discard those edits.

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [Triage & alert correlation](notebooks/01_triage_and_correlation.ipynb) | Raw alerts → incidents via `/incidents/correlate`; prioritization by severity + confidence (alerts **and cross-incident campaign links**) + blast radius + containment; self-check |
| 2 | [Entity-centric investigation](notebooks/02_entity_pivot_investigation.ipynb) | Pivot a user entity across email / sign-in / endpoint / network; reconstruct the full kill chain; auto-generate an incident report; self-check |
| 3 | [Incident lifecycle](notebooks/03_incident_lifecycle.ipynb) | Assign, comment, classify **from evidence** (TP/BP/FP/Undetermined — with the two-column test), close, and tune rules; self-check |
| 4 | [Automated response & IOCs](notebooks/04_automated_response.ipynb) | Sentinel automation rules vs playbooks vs Defender XDR AIR, watchlist IOC matching, containment vs eradication vs recovery, when to trust automation; self-check |

## Quick start

```bash
cd security-certs/sc-200/02-incident-response

# 1. Start the mini-SIEM. This lab's compose file extends Lab 1's, so you get the
#    same server with its own copy of the database -- nothing here disturbs Lab 1.
docker compose up -d --wait

# 2. Install this lab's deps
uv sync
```

Only one lab in this track can run at a time: all three publish host port 8000.
If `up` fails with *port is already allocated*, tear the other one down first.

Open any notebook in VS Code and pick the **`.venv` kernel** from this folder
(top-right kernel picker). If it does not appear, reload the window
(`Cmd+Shift+P` → `Reload Window`).

## Resetting state between runs

The notebooks mutate incidents, playbooks, and watchlists. They're written to be
safely rerunnable, but if you want a pristine starting point:

```bash
docker compose down -v && docker compose up -d --wait
```

The `-v` wipes the seeded database; the log generator then reseeds attack data.

