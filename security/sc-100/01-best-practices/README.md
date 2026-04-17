# Lab 1: Design Solutions Aligned with Security Best Practices

📖 **Exam domain**: Design solutions that align with security best practices and priorities (20–25%)

## What you'll design

- Ransomware resiliency strategies with BCDR
- Zero Trust architecture using RaMP (Rapid Modernization Plan)
- Solutions aligned with MCRA (Microsoft Cybersecurity Reference Architectures) and MCSB
- Security strategies using CAF (Cloud Adoption Framework) and WAF (Well-Architected Framework)
- DevSecOps pipeline security

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [Ransomware resiliency](notebooks/01_ransomware_resiliency.ipynb) | Threat prioritization, BCDR design, privileged access protection |
| 2 | [Frameworks and Zero Trust](notebooks/02_frameworks_and_zero_trust.ipynb) | MCRA, MCSB, CAF, WAF, Zero Trust RaMP, landing zones |

## Quick start

```bash
cd security/sc-100/01-best-practices
uv sync
uv run python -m ipykernel install --user --name=sc-100 --display-name="SC-100 (Python)"
```
