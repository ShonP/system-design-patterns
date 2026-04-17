# Lab 4: Defender for Cloud and Microsoft Sentinel

📖 **Exam domain**: Secure Azure using Microsoft Defender for Cloud and Microsoft Sentinel (30–35%)

This is the **largest** AZ-500 domain.

## What you'll implement

- Azure Policy — built-in and custom policies, initiatives, compliance
- Key Vault — access control, network settings, key rotation, backup/recovery
- Defender for Cloud — Secure Score, compliance standards, workload protection plans
- Defender for Servers, Databases, Storage — configuration and management
- External Attack Surface Management (EASM)
- Microsoft Sentinel — data connectors, analytics rules, automation (playbooks)
- Alert management and workflow automation

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [Azure Policy and Key Vault](notebooks/01_azure_policy_and_key_vault.ipynb) | Policy definitions, initiatives, Key Vault access, key rotation |
| 2 | [Defender for Cloud](notebooks/02_defender_for_cloud.ipynb) | CSPM, CWPP, Secure Score, compliance, Defender plans, EASM |
| 3 | [Sentinel implementation](notebooks/03_sentinel_implementation.ipynb) | Data connectors, analytics rules, KQL, automation, incident response |

## Quick start

```bash
cd security/az-500/04-defender-and-sentinel
uv sync
uv run python -m ipykernel install --user --name=az-500 --display-name="AZ-500 (Python)"
```
