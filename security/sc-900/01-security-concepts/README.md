# Lab 1: Security, Compliance & Identity Concepts

📖 **Exam domain**: Describe the concepts of security, compliance, and identity (10–15%)

## What you'll learn

This lab covers the foundational mental models that every security topic builds on. After completing it you should be able to explain:

- **Shared responsibility model** — who secures what in IaaS / PaaS / SaaS
- **Defense in depth** — layered security (physical → network → application → data)
- **Zero Trust** — "never trust, always verify" with the three principles
- **Encryption & hashing** — symmetric vs asymmetric, hashing vs encryption, why salting matters
- **GRC** — governance, risk, and compliance frameworks

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [Security models](notebooks/01_security_models.ipynb) | Shared responsibility, defense in depth, Zero Trust |
| 2 | [Encryption and hashing](notebooks/02_encryption_and_hashing.ipynb) | Symmetric/asymmetric encryption, hashing, salting, real-world attacks |

## Quick start

```bash
cd security/sc-900/01-security-concepts

uv sync
uv run python -m ipykernel install --user --name=sc-900 --display-name="SC-900 (Python)"
```

No Docker needed — these labs are pure Python.
