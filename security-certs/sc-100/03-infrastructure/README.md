# Lab 3: Infrastructure Security Design

📖 **Exam domain**: Design security solutions for infrastructure (25–30%)

## What you'll design

- Security posture management with Defender for Cloud (CSPM + CWPP)
- Azure Arc for hybrid and multicloud governance
- External Attack Surface Management (Defender EASM) and Microsoft Security Exposure Management
- Endpoint security strategy (servers, mobile, IoT/OT)
- Network segmentation and Zero Trust networking
- Microsoft Entra Internet Access / Private Access (SSE)
- Container and AKS security architecture
- AI services security and security baselines

## Notebooks

Each notebook starts with a **glossary** and a **bad practice → best practice** table so beginners can orient themselves before the deeper design exercises.

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [Posture and endpoints](notebooks/01_posture_and_endpoints.ipynb) | Defender for Cloud, CSPM vs CWPP, Arc, EASM, endpoint strategy, LAPS, posture-maturity scorer |
| 2 | [Network and services security](notebooks/02_network_and_services_security.ipynb) | Network segmentation, SSE/ZTNA, container/AKS, AI security, MCSB baselines, NSG audit + Azure Policy example |

## Quick start

```bash
cd security-certs/sc-100/03-infrastructure
uv sync
# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/
```
