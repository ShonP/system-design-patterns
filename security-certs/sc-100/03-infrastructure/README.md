# Lab 3: Infrastructure Security Design

📖 **Exam domain**: Design security solutions for infrastructure (20–25%)

## What you'll design

- Security posture management with Defender for Cloud (CSPM + CWPP)
- Azure Arc for hybrid and multicloud governance
- External Attack Surface Management (EASM)
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
cd security/sc-100/03-infrastructure
uv sync
uv run python -m ipykernel install --user --name=sc-100 --display-name="SC-100 (Python)"
```
