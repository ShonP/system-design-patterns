# Lab 4: Application and Data Security Design

📖 **Exam domain**: Design security solutions for applications and data (20–25%)

## What you'll design

- Threat modeling with STRIDE methodology
- DevSecOps pipeline security architecture
- Workload identity and API security design
- WAF deployment patterns
- Data classification and encryption strategies
- Database security (Azure SQL, Cosmos DB, Synapse)
- Microsoft 365 security with Purview and Defender for Office 365
- Intune device management and Copilot data security
- End-to-end security architecture capstone

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [Application security design](notebooks/01_application_security_design.ipynb) | Threat modeling, DevSecOps, workload identity, API security, WAF |
| 2 | [Data security design](notebooks/02_data_security_design.ipynb) | Data classification, encryption, database security, M365 security, capstone |

## Quick start

```bash
cd security/sc-100/04-applications-and-data
uv sync
uv run python -m ipykernel install --user --name=sc-100 --display-name="SC-100 (Python)"
```
