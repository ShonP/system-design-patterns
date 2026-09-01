# Lab 1: Design Solutions Aligned with Security Best Practices

📖 **Exam domain**: Design solutions that align with security best practices and priorities (20–25%)

## What you'll design

- Ransomware resiliency strategies with BCDR
- Zero Trust architecture using the **Zero Trust adoption framework** (the current name for what older material calls RaMP, the Rapid Modernization Plan)
- Solutions aligned with MCRA (Microsoft Cybersecurity Reference Architectures) and MCSB
- Security strategies using CAF (Cloud Adoption Framework) and WAF (Well-Architected Framework)
- DevSecOps pipeline security

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [Ransomware resiliency](notebooks/01_ransomware_resiliency.ipynb) | RTO/RPO, immutable backups, PIM, bad→best backup design, posture scoring, 90-day plan |
| 2 | [Frameworks and Zero Trust](notebooks/02_frameworks_and_zero_trust.ipynb) | MCRA, MCSB, CAF, WAF (Well-Architected vs Web Application Firewall), Zero Trust adoption framework, landing zones, auto-graded quiz |
| 3 | [DevSecOps & Shared Responsibility](notebooks/03_devsecops_and_shared_responsibility.ipynb) | Shared responsibility matrix, DevSecOps pipeline, STRIDE threat modeling, defense in depth |

Each notebook follows the repo convention of **bad → better → best** progression and uses only the Python standard library.

## Quick start

```bash
cd security-certs/sc-100/01-best-practices
uv sync
```

Then open any notebook in VS Code and pick the **.venv (Python)** kernel from the top-right kernel selector. If it doesn't appear, reload the window (`Cmd+Shift+P` → *Reload Window*).

## Verify all notebooks run

```bash
for nb in notebooks/*.ipynb; do
  uv run jupyter nbconvert --to notebook --execute "$nb" --output /tmp/_out.ipynb
done
```
