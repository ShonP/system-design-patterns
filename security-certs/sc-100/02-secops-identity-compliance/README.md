# Lab 2: Security Operations, Identity & Compliance Design

📖 **Exam domain**: Design security operations, identity & access, and compliance capabilities (30–35%)

## What you'll design

- SOC architecture with SIEM + XDR integration patterns
- SOAR automation and incident response workflows
- Enterprise access model with Conditional Access policies
- Privileged access strategy (PIM, PAW, break-glass accounts)
- External identity management (B2B, decentralized identity)
- Compliance architecture with Purview, Azure Policy, and Defender compliance

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [Security operations design](notebooks/01_security_operations_design.ipynb) | Glossary, bad→best practices, SIEM vs XDR, Sentinel architecture, SOAR, MITRE ATT&CK, **runnable detection engine**, SolarWinds case study |
| 2 | [Identity and compliance design](notebooks/02_identity_and_compliance_design.ipynb) | Glossary, bad→best practices, Enterprise access model, **runnable Conditional Access evaluator**, PIM, **Zero Trust maturity scorer**, Purview, Azure Policy, Midnight Blizzard case study |

## Quick start

```bash
cd security/sc-100/02-secops-identity-compliance
uv sync
uv run python -m ipykernel install --user --name=sc-100 --display-name="SC-100 (Python)"
```
