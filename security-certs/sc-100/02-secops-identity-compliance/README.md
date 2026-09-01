# Lab 2: Security Operations, Identity & Compliance Design

📖 **Exam domain**: Design security operations, identity, and compliance capabilities (25–30%)

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
| 2 | [Identity and compliance design](notebooks/02_identity_and_compliance_design.ipynb) | Glossary, bad→best practices, **Zero Trust maturity scorer**, Enterprise access model, Conditional Access evaluation order + **runnable CA evaluator**, PIM / PAW / break-glass, Purview, Azure Policy, Midnight Blizzard case study |

## Quick start

```bash
cd security-certs/sc-100/02-secops-identity-compliance
uv sync
# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/
```
