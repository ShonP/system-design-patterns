# Lab 3: Azure Security Solutions

📖 **Exam domain**: Describe the capabilities of Microsoft security solutions (35–40%)

This is the **largest** domain on the SC-900 exam. It covers Azure infrastructure security (NSGs, Firewall, Key Vault), security management (Defender for Cloud), SIEM/SOAR (Sentinel), and threat protection (Defender XDR).

## What you'll learn

- Azure network security — DDoS Protection, Azure Firewall, WAF, NSGs, VNets, Bastion
- Azure Key Vault — secrets, keys, certificates
- Microsoft Defender for Cloud — CSPM, security posture, workload protection
- Microsoft Sentinel — SIEM/SOAR, KQL queries, threat detection
- Microsoft Defender XDR — Defender for Endpoint, Office 365, Cloud Apps, Identity

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [Network security](notebooks/01_network_security.ipynb) | DDoS, Firewall, WAF, VNets, NSGs, Bastion |
| 2 | [Key Vault and Defender](notebooks/02_key_vault_and_defender.ipynb) | Key Vault, Defender for Cloud, CSPM |
| 3 | [Sentinel and Defender XDR](notebooks/03_sentinel_and_defender_xdr.ipynb) | SIEM vs SOAR, KQL, Sentinel, Defender XDR services |

Each notebook ends with an auto-graded **self-check quiz** — edit `MY_ANSWERS` and re-run the cell.

## Quick start

```bash
cd security-certs/sc-900/03-azure-security-solutions

uv sync
# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/
```

No Docker needed — these labs use pure-Python simulations of the Azure services.

### Name changes the exam expects you to know

| Old name | Current name |
|---|---|
| Azure AD | Microsoft Entra ID |
| Azure Security Center / Azure Defender | Microsoft Defender for Cloud |
| Azure Sentinel | Microsoft Sentinel |
| Azure Advanced Threat Protection (Azure ATP) | Microsoft Defender for Identity |
| Microsoft Cloud App Security (MCAS) | Microsoft Defender for Cloud Apps |
| Microsoft 365 Defender | Microsoft Defender XDR |
| DDoS Protection Basic / Standard | Infrastructure protection (free) / DDoS Network Protection (+ DDoS IP Protection) |
