# Lab 4: Defender for Cloud and Microsoft Sentinel

📖 **Exam domain**: Secure Azure using Microsoft Defender for Cloud and Microsoft Sentinel (30–35%)

This is the **largest** AZ-500 domain.

## What you'll implement

- Azure Policy — built-in and custom policies, initiatives, compliance, all effects (incl. Append / DenyAction / Manual)
- Key Vault — RBAC vs access policy, soft-delete + purge protection, key rotation, hardening
- Defender for Cloud — CSPM vs CWPP, Secure Score math, plan advisor, cost estimator, compliance
- Defender for Servers / SQL / Storage / Containers / Key Vault — when to use each plan
- External Attack Surface Management (EASM)
- Microsoft Sentinel — KQL pipeline, all analytics rule types (Scheduled / NRT / Microsoft Security / Fusion / ML Behavior / Anomaly), incidents, entity mapping, MITRE tactics, UEBA
- Automation — Sentinel playbooks (Logic Apps) and Defender for Cloud workflow automation

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [Azure Policy and Key Vault](notebooks/01_azure_policy_and_key_vault.ipynb) | Mini policy engine, all policy effects, initiative scoring, Key Vault RBAC vs access policy, soft-delete/purge lifecycle, rotation scanner, bad→best hardening, self-check |
| 2 | [Defender for Cloud](notebooks/02_defender_for_cloud.ipynb) | CSPM vs CWPP, Secure Score calculator + exemption pitfalls, plan advisor (P1 vs P2), cost estimator, compliance mapping, multi-cloud, EASM, bad→best rollout, self-check |
| 3 | [Sentinel implementation](notebooks/03_sentinel_implementation.ipynb) | Mini KQL interpreter, analytics rules that fire on sim events, incidents + entities + ATT&CK, playbook simulation, DCRs, UEBA, bad→best rollout, self-check |

Every notebook runs end-to-end in plain Python — no Azure subscription required — follows a **bad → best** progression so you can see the exam-worthy contrast between defaults and a hardened setup, and ends with a **self-check quiz plus answers**.

## Quick start

```bash
cd security-certs/az-500/04-defender-and-sentinel
uv sync
# Then open any notebook in VS Code and pick the .venv kernel (top-right picker).
# If the kernel doesn't appear: Cmd+Shift+P → "Developer: Reload Window".
```

Or execute all notebooks headlessly to verify they run:

```bash
uv run jupyter nbconvert --to notebook --execute --inplace notebooks/*.ipynb
```
