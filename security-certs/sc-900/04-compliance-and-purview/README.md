# Lab 4: Compliance and Microsoft Purview

📖 **Exam domain**: Describe the capabilities of Microsoft compliance solutions (20–25%)

## What you'll learn

- Service Trust Portal and Microsoft's privacy principles
- Microsoft Purview portal and Compliance Manager (compliance score)
- Microsoft Priva and Subject Rights Requests (GDPR/CCPA)
- Data classification — sensitive info types, trainable classifiers
- Sensitivity labels and Data Loss Prevention (DLP)
- Records management and retention policies
- Insider Risk Management and Communication Compliance
- eDiscovery (Standard and Premium capabilities, now delivered through the unified Purview eDiscovery experience) and Audit

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [Compliance fundamentals](notebooks/01_compliance_fundamentals.ipynb) | Service Trust Portal, shared responsibility, Compliance Manager scoring, Priva + Subject Rights Requests |
| 2 | [Information protection and DLP](notebooks/02_information_protection_and_dlp.ipynb) | Sensitive info types, auto-labeling, DLP (bad → best), retention, end-to-end scenario |
| 3 | [Insider risk, Communication Compliance, eDiscovery, and Audit](notebooks/03_insider_risk_and_ediscovery.ipynb) | Insider risk scoring, Communication Compliance, legal holds, audit log search |

## Quick start

```bash
cd security-certs/sc-900/04-compliance-and-purview

uv sync
```

Then open any notebook in VS Code and select the `.venv` kernel from the kernel picker (top-right of the notebook). If the `.venv` kernel doesn't show up, reload the VS Code window (`Cmd+Shift+P` → *Developer: Reload Window*).

No Docker needed — all Purview features are simulated in Python.

Each notebook ends with an auto-graded **self-check quiz** — edit `MY_ANSWERS` and re-run the cell.
