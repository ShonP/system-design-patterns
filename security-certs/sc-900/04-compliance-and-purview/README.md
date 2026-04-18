# Lab 4: Compliance and Microsoft Purview

📖 **Exam domain**: Describe the capabilities of Microsoft compliance solutions (20–25%)

## What you'll learn

- Service Trust Portal and Microsoft's privacy principles
- Microsoft Purview portal and Compliance Manager (compliance score)
- Data classification — sensitive info types, trainable classifiers
- Sensitivity labels and Data Loss Prevention (DLP)
- Records management and retention policies
- Insider risk management, eDiscovery, and audit

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [Compliance fundamentals](notebooks/01_compliance_fundamentals.ipynb) | Service Trust Portal, Compliance Manager, compliance score, Priva |
| 2 | [Information protection and DLP](notebooks/02_information_protection_and_dlp.ipynb) | Data classification, sensitivity labels, DLP, retention |
| 3 | [Insider risk and eDiscovery](notebooks/03_insider_risk_and_ediscovery.ipynb) | Insider risk, eDiscovery, audit |

## Quick start

```bash
cd security/sc-900/04-compliance-and-purview

uv sync
uv run python -m ipykernel install --user --name=sc-900 --display-name="SC-900 (Python)"
```

No Docker needed.
